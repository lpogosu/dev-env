# Output helpers and the change counter.
#
# Every action in this repository ends in exactly one of two calls: log_change
# when it touched the machine, log_keep when it found the machine already in
# the wanted state. The final summary line is what the container test greps to
# prove the second bootstrap run is a no-op, so the counters are not cosmetic.
#
# Sourced by bootstrap.sh; not executable on its own.

DEVENV_CHANGED=0
DEVENV_UNCHANGED=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != dumb ]; then
    DEVENV_DIM=$(printf '\033[2m')
    DEVENV_BOLD=$(printf '\033[1m')
    DEVENV_YELLOW=$(printf '\033[33m')
    DEVENV_RED=$(printf '\033[31m')
    DEVENV_OFF=$(printf '\033[0m')
else
    DEVENV_DIM=
    DEVENV_BOLD=
    DEVENV_YELLOW=
    DEVENV_RED=
    DEVENV_OFF=
fi

log_step() {
    printf '\n%s==> %s%s\n' "$DEVENV_BOLD" "$1" "$DEVENV_OFF"
}

log_change() {
    DEVENV_CHANGED=$((DEVENV_CHANGED + 1))
    printf '    %schanged%s  %s\n' "$DEVENV_YELLOW" "$DEVENV_OFF" "$1"
}

log_keep() {
    DEVENV_UNCHANGED=$((DEVENV_UNCHANGED + 1))
    printf '    %sok       %s%s\n' "$DEVENV_DIM" "$1" "$DEVENV_OFF"
}

log_info() {
    printf '    %s\n' "$1"
}

log_warn() {
    printf '    %swarning%s  %s\n' "$DEVENV_YELLOW" "$DEVENV_OFF" "$1" >&2
}

log_fail() {
    printf '%serror%s  %s\n' "$DEVENV_RED" "$DEVENV_OFF" "$1" >&2
    exit 1
}

log_summary() {
    printf '\nsummary: changed=%s unchanged=%s\n' "$DEVENV_CHANGED" "$DEVENV_UNCHANGED"
}
