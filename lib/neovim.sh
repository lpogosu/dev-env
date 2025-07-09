# Neovim: a pinned upstream build, and plugins restored from the lockfile.
#
# The distribution package is not usable here. Debian 12 ships Neovim 0.7, which
# predates most of the Lua API this configuration uses; Fedora is current but a
# configuration that only works on one of the two supported platforms is not a
# configuration. So the release tarball is pinned by version and SHA-256 in
# packages/versions.env, exactly like any other artefact that is not signed by a
# distribution.
#
# Sourced by bootstrap.sh; not executable on its own.

DEVENV_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dev-env"

install_neovim() {
    log_step "Neovim"

    if [ "$DEVENV_PLATFORM" = macos ]; then
        # Homebrew tracks upstream closely and the Brewfile already asks for it.
        log_keep "neovim (managed by Homebrew)"
        return 0
    fi

    # shellcheck source=packages/versions.env
    . "$DEVENV_ROOT/packages/versions.env"

    case $DEVENV_ARCH in
        x86_64) nvim_sha=$NVIM_SHA256_LINUX_X86_64 ;;
        arm64) nvim_sha=$NVIM_SHA256_LINUX_ARM64 ;;
        *) log_fail "no Neovim checksum recorded for $DEVENV_ARCH" ;;
    esac

    nvim_prefix="${DEVENV_PREFIX:-/usr/local}"
    nvim_home="$nvim_prefix/lib/nvim-$NVIM_VERSION"
    nvim_link="$nvim_prefix/bin/nvim"

    if [ -x "$nvim_home/bin/nvim" ] && [ "$(readlink "$nvim_link" 2>/dev/null)" = "$nvim_home/bin/nvim" ]; then
        log_keep "neovim $NVIM_VERSION"
        return 0
    fi

    nvim_tarball="$DEVENV_CACHE/nvim-linux-$DEVENV_ARCH-$NVIM_VERSION.tar.gz"
    mkdir -p "$DEVENV_CACHE"

    if [ ! -f "$nvim_tarball" ]; then
        log_info "downloading Neovim $NVIM_VERSION ($DEVENV_ARCH)"
        curl -fsSL -o "$nvim_tarball.part" \
            "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/nvim-linux-$DEVENV_ARCH.tar.gz"
        mv "$nvim_tarball.part" "$nvim_tarball"
    fi

    nvim_got=$(file_sha256 "$nvim_tarball")
    if [ "$nvim_got" != "$nvim_sha" ]; then
        # Drop the bad artefact so a rerun re-downloads instead of failing on
        # the same cached bytes forever.
        rm -f "$nvim_tarball"
        log_fail "Neovim checksum mismatch: expected $nvim_sha, got $nvim_got"
    fi

    # Unpack beside the target and move into place, so an interrupted run never
    # leaves a half-extracted tree that the check above would accept.
    nvim_staging="$nvim_home.incoming.$$"
    as_root rm -rf "$nvim_staging"
    as_root mkdir -p "$nvim_staging"
    as_root tar -xzf "$nvim_tarball" -C "$nvim_staging" --strip-components=1
    as_root rm -rf "$nvim_home"
    as_root mv "$nvim_staging" "$nvim_home"
    as_root mkdir -p "$nvim_prefix/bin"
    as_root ln -sfn "$nvim_home/bin/nvim" "$nvim_link"
    log_change "neovim $NVIM_VERSION at $nvim_home"
}

# Installs lazy.nvim itself and then restores every plugin to the commit
# recorded in lazy-lock.json. The editor is configured never to install
# anything on its own (install.missing = false), so this is the only moment at
# which plugin code changes.
sync_neovim_plugins() {
    log_step "Neovim plugins"

    nvim_lock="$DEVENV_ROOT/home/.config/nvim/lazy-lock.json"
    nvim_lazy_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
    nvim_stamp="$DEVENV_STATE/nvim-lazy-lock.sha256"
    nvim_lock_sha=$(file_sha256 "$nvim_lock")

    if [ -d "$nvim_lazy_dir" ] && [ "$(cat "$nvim_stamp" 2>/dev/null)" = "$nvim_lock_sha" ]; then
        log_keep "plugins at lazy-lock.json revision"
        return 0
    fi

    # lazy.nvim cannot pin itself: it has to be on disk before it can read the
    # lockfile. So the commit is read out of the lockfile here, with sed rather
    # than jq — the file is written by lazy in a fixed one-line-per-plugin
    # format, and the bootstrap should not need a JSON parser to start.
    nvim_lazy_commit=$(sed -n \
        's/.*"lazy\.nvim":.*"commit": *"\([0-9a-f]\{7,40\}\)".*/\1/p' "$nvim_lock")
    [ -n "$nvim_lazy_commit" ] || log_fail "lazy-lock.json does not pin lazy.nvim"

    if [ ! -d "$nvim_lazy_dir" ]; then
        mkdir -p "$(dirname "$nvim_lazy_dir")"
        # blob:none keeps the clone to the commit graph plus one checkout.
        git clone --quiet --filter=blob:none \
            https://github.com/folke/lazy.nvim.git "$nvim_lazy_dir"
    fi
    if [ "$(git -C "$nvim_lazy_dir" rev-parse HEAD)" != "$nvim_lazy_commit" ]; then
        git -C "$nvim_lazy_dir" fetch --quiet origin "$nvim_lazy_commit" 2>/dev/null || true
        git -C "$nvim_lazy_dir" -c advice.detachedHead=false \
            checkout --quiet "$nvim_lazy_commit"
    fi

    # install then restore: `install` clones what is missing, `restore` moves
    # every plugin — the newly cloned ones included — to the commit in the
    # lockfile. `restore` alone is not enough on a machine where nothing is
    # cloned yet, because the editor is configured never to install on its own.
    if ! nvim --headless '+Lazy! install' '+Lazy! restore' +qa >"$DEVENV_TMP/lazy.log" 2>&1; then
        cat "$DEVENV_TMP/lazy.log" >&2
        log_fail "lazy.nvim could not restore the plugins"
    fi

    nvim_lock_after=$(file_sha256 "$nvim_lock")
    if [ "$nvim_lock_after" != "$nvim_lock_sha" ]; then
        # The lockfile is the input, not the output. If a bootstrap rewrote it,
        # the next machine would get different plugin revisions than this one.
        log_fail "lazy.nvim rewrote $nvim_lock during the bootstrap"
    fi

    mkdir -p "$DEVENV_STATE"
    printf '%s\n' "$nvim_lock_sha" >"$nvim_stamp"
    log_change "plugins restored to lazy-lock.json revision"
}
