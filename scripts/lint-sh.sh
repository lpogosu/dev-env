#!/bin/sh
# ShellCheck over every shell file in the repository.
#
# Only the entry points are listed. The files under lib/ have no shebang and
# no meaning on their own, so they are reached through the `# shellcheck
# source=` directives in bootstrap.sh; --check-sourced then reports problems
# inside them as well, which is the part most setups forget to turn on.
# --shell=sh is explicit because a sourced file has no shebang to infer from.
#
# Falls back to the pinned container image when shellcheck is not installed,
# which is the case on a Windows workstation and not the case on a CI runner.
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
image=koalaman/shellcheck:v0.11.0

set -- --shell=sh --external-sources --check-sourced --severity=style \
    bootstrap.sh \
    scripts/gen-packages.sh \
    scripts/lint-sh.sh \
    scripts/lint-lua.sh \
    scripts/bench-zsh.sh \
    tests/run.sh \
    tests/suite.sh

if command -v shellcheck >/dev/null 2>&1; then
    cd "$root"
    exec shellcheck "$@"
fi

if ! command -v docker >/dev/null 2>&1; then
    printf 'neither shellcheck nor docker is available\n' >&2
    exit 1
fi

exec docker run --rm -v "$root:/mnt:ro" -w /mnt "$image" "$@"
