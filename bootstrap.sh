#!/bin/sh
# Take a fresh Debian, Fedora or macOS machine to a working development
# environment. Safe to run repeatedly: the second run reports changed=0.
#
# POSIX sh, deliberately. This script runs before anything is installed, and
# /bin/sh is the only interpreter all three platforms are guaranteed to have at
# that moment. See the "Решения и компромиссы" section of the README.
set -eu

DEVENV_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
DEVENV_TMP=$(mktemp -d "${TMPDIR:-/tmp}/dev-env.XXXXXX")
trap 'rm -rf "$DEVENV_TMP"' EXIT INT TERM

# shellcheck source=lib/log.sh
. "$DEVENV_ROOT/lib/log.sh"
# shellcheck source=lib/platform.sh
. "$DEVENV_ROOT/lib/platform.sh"
# shellcheck source=lib/links.sh
. "$DEVENV_ROOT/lib/links.sh"
# shellcheck source=lib/packages.sh
. "$DEVENV_ROOT/lib/packages.sh"
# shellcheck source=lib/neovim.sh
. "$DEVENV_ROOT/lib/neovim.sh"

usage() {
    cat <<'USAGE'
usage: bootstrap.sh [options]

  --no-packages   skip the package manager stage
  --no-plugins    skip installing Neovim and its plugins
  --no-shell      do not change the login shell to zsh
  -h, --help      show this message

Every stage checks the current state before acting, so skipping a stage is only
about time, never about safety. Running the script twice in a row must report
"changed=0" the second time; tests/suite.sh asserts exactly that.
USAGE
}

do_packages=1
do_neovim=1
do_shell=1

while [ $# -gt 0 ]; do
    case $1 in
        --no-packages) do_packages=0 ;;
        --no-plugins) do_neovim=0 ;;
        --no-shell) do_shell=0 ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            log_fail "unknown option: $1"
            ;;
    esac
    shift
done

# Machine-local overrides. Each of these is sourced last by the file it belongs
# to, is created empty here, and is never tracked by this repository. This is
# the whole answer to "where do I put the things that must not be public".
seed_local_files() {
    log_step "Machine-local overrides"

    seed_local_file .config/zsh/local.zsh <<'LOCAL'
# Sourced last by ~/.config/zsh/.zshrc, after every module in this repository.
# Machine-specific PATH entries, credentials and one-off aliases belong here.
# Nothing in this file is tracked.
LOCAL

    seed_local_file .config/git/local.config <<'LOCAL'
# Included first by ~/.config/git/config, which sets user.useConfigOnly, so git
# refuses to commit until an identity is defined here. Put the identity that
# belongs to this machine and no other in it:
#
# [user]
#     name = lpogosu
#     email = 115780379+lpogosu@users.noreply.github.com
LOCAL

    seed_local_file .config/tmux/local.conf <<'LOCAL'
# Sourced last by ~/.config/tmux/tmux.conf. Terminal-specific overrides only.
LOCAL

    seed_local_file .ssh/config.d/00-local.conf <<'LOCAL'
# Read before the defaults in ~/.ssh/config. OpenSSH keeps the first value it
# sees for each option, so anything here wins over the tracked defaults.
LOCAL
}

set_login_shell() {
    log_step "Login shell"

    shell_zsh=$(command -v zsh 2>/dev/null || true)
    if [ -z "$shell_zsh" ]; then
        log_warn "zsh is not on PATH; login shell left alone"
        return 0
    fi

    if [ "$DEVENV_PLATFORM" = macos ]; then
        # `dscl` is the supported way on macOS and it prompts for a password;
        # doing it silently from a bootstrap script is worse than saying so.
        log_warn "set the login shell manually: chsh -s $shell_zsh"
        return 0
    fi

    shell_user=$(id -un)
    shell_current=$(getent passwd "$shell_user" | cut -d: -f7)
    if [ "$shell_current" = "$shell_zsh" ]; then
        log_keep "login shell is $shell_zsh"
        return 0
    fi

    # chsh only accepts shells listed in /etc/shells.
    if ! grep -qx "$shell_zsh" /etc/shells 2>/dev/null; then
        log_warn "$shell_zsh is not listed in /etc/shells; login shell left alone"
        return 0
    fi

    as_root chsh -s "$shell_zsh" "$shell_user"
    log_change "login shell set to $shell_zsh"
}

detect_platform
detect_privileges

printf '%sdev-env%s  platform=%s arch=%s home=%s\n' \
    "$DEVENV_BOLD" "$DEVENV_OFF" "$DEVENV_PLATFORM" "$DEVENV_ARCH" "$HOME"

if [ "$do_packages" -eq 1 ]; then
    install_packages
fi

log_step "Directories"
ensure_dir_mode .ssh 700
ensure_dir_mode .ssh/config.d 700
# ControlPath in ~/.ssh/config points here; ssh does not create it and reports
# the failure as a connection error.
ensure_dir_mode .ssh/control 700

link_dotfiles
seed_local_files

if [ "$do_neovim" -eq 1 ]; then
    install_neovim
    sync_neovim_plugins
fi

if [ "$do_shell" -eq 1 ]; then
    set_login_shell
fi

log_summary
