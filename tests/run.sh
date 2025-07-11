#!/bin/sh
# Run tests/suite.sh inside a throwaway container for each supported Linux.
#
# The repository is mounted read-only: the bootstrap writes to $HOME and to the
# cache directory and to nothing else, and a read-only mount is the cheapest way
# to keep that true.
#
# DEVENV_HOST_ROOT exists for hosts where the path the docker daemon needs is
# not the path this script sees — a Windows checkout driven from Git Bash, for
# instance.
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
mount_source=${DEVENV_HOST_ROOT:-$root}
images=${IMAGES:-'debian:12-slim fedora:41'}

status=0
for image in $images; do
    printf '\n===================== %s =====================\n' "$image"
    if docker run --rm -i \
        -v "$mount_source:/mnt/dev-env:ro" \
        -e HOME=/root \
        -e "RUNS=${RUNS:-50}" \
        "$image" sh /mnt/dev-env/tests/suite.sh; then
        printf '%s: passed\n' "$image"
    else
        printf '%s: FAILED\n' "$image"
        status=1
    fi
done

exit "$status"
