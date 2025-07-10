# Package installation.
#
# The lists under packages/ are generated from packages/manifest.tsv, so a tool
# is added in exactly one place and cannot be present on one platform and quietly
# missing on another. Nothing here calls the package manager unconditionally:
# every package is queried first, so a run that installs nothing reports nothing
# as changed.
#
# Sourced by bootstrap.sh; not executable on its own.

# Package names for the current platform, comments and blank lines removed.
packages_wanted() {
    packages_file="$DEVENV_ROOT/packages/$DEVENV_PLATFORM.txt"
    [ -r "$packages_file" ] || log_fail "missing package list: $packages_file"
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$packages_file" | grep -v '^$'
}

package_installed() {
    case $DEVENV_PLATFORM in
        debian)
            # db:Status-Status is "installed" only for a fully configured
            # package; a bare `dpkg -l` would also match removed-but-not-purged.
            package_status=$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null || true)
            [ "$package_status" = installed ]
            ;;
        fedora)
            rpm -q --quiet "$1"
            ;;
        macos)
            brew list --formula "$1" >/dev/null 2>&1
            ;;
    esac
}

# Installs every name passed as an argument in one call to the package manager.
packages_install() {
    case $DEVENV_PLATFORM in
        debian)
            # The index is only refreshed when something actually has to be
            # installed; refreshing it on every run would be a guaranteed
            # network round trip for a no-op bootstrap.
            DEBIAN_FRONTEND=noninteractive as_root apt-get update -qq
            DEBIAN_FRONTEND=noninteractive as_root apt-get install -y \
                --no-install-recommends -o Dpkg::Use-Pty=0 "$@"
            ;;
        fedora)
            as_root dnf install -y --setopt=install_weak_deps=False "$@"
            ;;
        macos)
            # Homebrew resolves the Brewfile itself; the names are only used
            # above to decide whether the call is needed at all.
            brew bundle install --file "$DEVENV_ROOT/packages/Brewfile" --no-upgrade
            ;;
    esac
}

install_packages() {
    log_step "Packages ($DEVENV_PLATFORM)"

    if [ "$DEVENV_PLATFORM" = macos ] && ! command -v brew >/dev/null 2>&1; then
        log_fail "Homebrew is not installed; see https://brew.sh"
    fi

    packages_wanted >"$DEVENV_TMP/packages"
    packages_todo=
    while IFS= read -r package_name; do
        if package_installed "$package_name"; then
            log_keep "package $package_name"
        else
            packages_todo="$packages_todo $package_name"
        fi
    done <"$DEVENV_TMP/packages"

    [ -n "$packages_todo" ] || return 0

    # shellcheck disable=SC2086  # deliberate splitting: package names never contain spaces
    packages_install $packages_todo

    for package_name in $packages_todo; do
        if package_installed "$package_name"; then
            log_change "package $package_name"
        else
            log_fail "package $package_name did not install"
        fi
    done
}
