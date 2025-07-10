#!/bin/sh
# StyLua --check over the Neovim configuration.
#
# The binary is pinned by version and SHA-256 in packages/versions.env and
# cached under .cache/bin, so the same version runs locally and in CI and a new
# upstream release cannot turn a green pipeline red on its own.
#
# There is no luacheck pass. luacheck needs a Lua interpreter and LuaRocks on
# the machine, and its value here would be catching undefined globals in a
# configuration whose only global is `vim` — which the container test already
# catches, because it loads the configuration in a real Neovim and fails on any
# error.
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
# shellcheck source=packages/versions.env
. "$root/packages/versions.env"

if command -v stylua >/dev/null 2>&1; then
    exec stylua --check "$root/home/.config/nvim"
fi

case $(uname -m) in
    x86_64 | amd64)
        asset=stylua-linux-x86_64.zip
        want=$STYLUA_SHA256_LINUX_X86_64
        ;;
    aarch64 | arm64)
        asset=stylua-linux-aarch64.zip
        want=$STYLUA_SHA256_LINUX_AARCH64
        ;;
    *)
        printf 'no StyLua build recorded for %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

bindir="$root/.cache/bin"
binary="$bindir/stylua-$STYLUA_VERSION"

if [ ! -x "$binary" ]; then
    mkdir -p "$bindir"
    archive="$bindir/$asset"
    curl -fsSL -o "$archive" \
        "https://github.com/JohnnyMorganz/StyLua/releases/download/$STYLUA_VERSION/$asset"
    got=$(sha256sum "$archive" | cut -d' ' -f1)
    if [ "$got" != "$want" ]; then
        rm -f "$archive"
        printf 'StyLua checksum mismatch: expected %s, got %s\n' "$want" "$got" >&2
        exit 1
    fi
    unzip -o -q "$archive" -d "$bindir"
    mv "$bindir/stylua" "$binary"
    chmod +x "$binary"
    rm -f "$archive"
fi

exec "$binary" --check "$root/home/.config/nvim"
