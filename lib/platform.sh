# Platform detection and the few portability shims the rest of the code needs.
#
# Three platforms are supported: Debian-family Linux, Fedora-family Linux and
# macOS. Anything else stops the run instead of guessing, because a wrong guess
# means running the wrong package manager as root.
#
# Sourced by bootstrap.sh; not executable on its own.

os_release_field() {
    sed -n "s/^$1=//p" /etc/os-release 2>/dev/null | tr -d '"' | head -n 1
}

# Sets DEVENV_PLATFORM (debian|fedora|macos) and DEVENV_ARCH (x86_64|arm64).
detect_platform() {
    case $(uname -s) in
        Darwin)
            DEVENV_PLATFORM=macos
            ;;
        Linux)
            [ -r /etc/os-release ] || log_fail "/etc/os-release is missing; cannot identify this Linux"
            platform_id=$(os_release_field ID)
            platform_like=$(os_release_field ID_LIKE)
            # ID_LIKE is a space-separated list, so pad both sides and match on
            # whole words: "rhel fedora" must not be matched by a bare "hel".
            case " $platform_id $platform_like " in
                *' debian '* | *' ubuntu '*) DEVENV_PLATFORM=debian ;;
                *' fedora '* | *' rhel '*) DEVENV_PLATFORM=fedora ;;
                *) log_fail "unsupported distribution: ${platform_id:-unknown}" ;;
            esac
            ;;
        *)
            log_fail "unsupported operating system: $(uname -s)"
            ;;
    esac

    case $(uname -m) in
        x86_64 | amd64) DEVENV_ARCH=x86_64 ;;
        aarch64 | arm64) DEVENV_ARCH=arm64 ;;
        *) log_fail "unsupported architecture: $(uname -m)" ;;
    esac
}

# Sets DEVENV_SUDO to "sudo" when escalation is needed and possible.
detect_privileges() {
    if [ "$(id -u)" -eq 0 ]; then
        DEVENV_SUDO=
    elif command -v sudo >/dev/null 2>&1; then
        DEVENV_SUDO=sudo
    else
        DEVENV_SUDO=
        log_warn "not root and sudo is unavailable; package installation will fail"
    fi
}

# Runs a command with escalation only when it is actually needed. A function
# rather than an unquoted "$DEVENV_SUDO" prefix, which would be a word-splitting
# accident waiting to happen.
as_root() {
    if [ -n "${DEVENV_SUDO:-}" ]; then
        "$DEVENV_SUDO" "$@"
    else
        "$@"
    fi
}

file_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        # macOS has no sha256sum; shasum ships with the system Perl.
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

# Octal permission bits of a path. GNU and BSD stat disagree on every flag.
file_mode() {
    if stat -c '%a' "$1" 2>/dev/null; then
        return 0
    fi
    stat -f '%Lp' "$1"
}
