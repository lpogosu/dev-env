# Symlink management, machine-local override files and directory modes.
#
# The interesting part of any dotfiles installer is not creating the symlink,
# it is deciding what to do when something is already at the target path. The
# rule here: nothing under $HOME is ever deleted or overwritten. Whatever is in
# the way is moved into a timestamped backup tree first, and the path it moved
# to is printed.
#
# Sourced by bootstrap.sh; not executable on its own.
#
# shellcheck disable=SC2088  # the tilde in the log messages is display text,
#                            # not a path this script is about to open

DEVENV_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dev-env"

# Created on first use so that an unchanged run leaves no empty directory
# behind, which would otherwise make the backup tree grow by one entry per run.
DEVENV_BACKUP_DIR=

ensure_backup_dir() {
    [ -n "$DEVENV_BACKUP_DIR" ] && return 0
    DEVENV_BACKUP_DIR="$DEVENV_STATE/backups/$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$DEVENV_BACKUP_DIR"
}

# Moves whatever occupies ~/$1 into the backup tree, preserving its path.
displace() {
    ensure_backup_dir
    displace_to="$DEVENV_BACKUP_DIR/$1"
    mkdir -p "$(dirname "$displace_to")"
    mv "$HOME/$1" "$displace_to"
    log_info "backed up ~/$1 to ${displace_to#"$HOME"/}"
}

# Relative paths of every file this repository owns, in a stable order.
tracked_paths() {
    (
        cd "$DEVENV_ROOT/home" || exit 1
        find . -type f | sed 's|^\./||' | LC_ALL=C sort
    )
}

link_file() {
    link_src="$DEVENV_ROOT/home/$1"
    link_dst="$HOME/$1"

    if [ -L "$link_dst" ]; then
        # A dangling symlink also lands here, which is what we want: it is in
        # the way, and its target may be a file the operator still cares about.
        if [ "$(readlink "$link_dst")" = "$link_src" ]; then
            log_keep "~/$1"
            return 0
        fi
        displace "$1"
    elif [ -e "$link_dst" ]; then
        displace "$1"
    fi

    mkdir -p "$(dirname "$link_dst")"
    ln -s "$link_src" "$link_dst"
    log_change "~/$1"
}

link_dotfiles() {
    log_step "Dotfiles"
    tracked_paths >"$DEVENV_TMP/tracked"
    # Redirection rather than a pipeline: a pipeline would run the loop in a
    # subshell and the change counters would be lost.
    while IFS= read -r tracked_rel; do
        link_file "$tracked_rel"
    done <"$DEVENV_TMP/tracked"
}

# Creates a directory with an exact mode. Used for ~/.ssh, where anything more
# permissive than 700 makes OpenSSH refuse to use the directory.
ensure_dir_mode() {
    ensure_dir_path="$HOME/$1"
    if [ ! -d "$ensure_dir_path" ]; then
        mkdir -p "$ensure_dir_path"
        chmod "$2" "$ensure_dir_path"
        log_change "~/$1 (mode $2)"
        return 0
    fi
    if [ "$(file_mode "$ensure_dir_path")" = "$2" ]; then
        log_keep "~/$1 (mode $2)"
        return 0
    fi
    chmod "$2" "$ensure_dir_path"
    log_change "~/$1 (mode corrected to $2)"
}

# Creates a machine-local file if it is absent, with content read from stdin.
# These files are the documented place for anything that must not be tracked:
# work identities, host aliases, API tokens. The repository never reads them
# back, it only guarantees they exist and are sourced last.
seed_local_file() {
    seed_dst="$HOME/$1"
    if [ -e "$seed_dst" ]; then
        # Still drain stdin, otherwise the caller's heredoc would leak into the
        # next command read by the shell.
        cat >/dev/null
        log_keep "~/$1 (machine-local)"
        return 0
    fi
    mkdir -p "$(dirname "$seed_dst")"
    cat >"$seed_dst"
    log_change "~/$1 (machine-local, created)"
}
