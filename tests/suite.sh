#!/bin/sh
# End-to-end test of a real bootstrap, meant to run inside a throwaway
# container. It installs packages, changes the login shell and writes all over
# $HOME, so it refuses to start unless it is told that is acceptable.
#
# What it proves, in order:
#   1. bootstrap.sh takes a base image to a working environment,
#   2. the shell, the editor and tmux actually work afterwards — asserted by
#      running them, not by checking that files exist,
#   3. an existing file at a target path is preserved, not overwritten,
#   4. machine-local overrides take precedence over the tracked configuration,
#   5. a second run changes nothing.
set -eu

source_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
root=$source_root

if [ "${DEVENV_TEST_I_KNOW_THIS_IS_DESTRUCTIVE:-}" != yes ] && [ ! -f /.dockerenv ]; then
    cat >&2 <<'REFUSE'
tests/suite.sh modifies $HOME, installs packages and changes the login shell.
Run it in a container: `make test`. To run it here anyway, set
DEVENV_TEST_I_KNOW_THIS_IS_DESTRUCTIVE=yes.
REFUSE
    exit 2
fi

# The repository arrives as a bind mount, and a bind mount from a host whose
# filesystem cannot express Unix permissions reports every file as 0777 and
# every file as non-executable. Both matter here: OpenSSH refuses to read a
# config file that anyone else can write, so the ssh assertions would fail for a
# reason that has nothing to do with the configuration. Copying the tree onto
# the container's own filesystem first makes the test measure the software
# rather than the host.
if [ "${DEVENV_TEST_COPY:-1}" = 1 ] && [ "$root" != /opt/dev-env ]; then
    mkdir -p /opt/dev-env
    cp -R "$source_root/." /opt/dev-env/
    chmod -R go-w /opt/dev-env
    find /opt/dev-env -name '*.sh' -exec chmod +x {} +
    root=/opt/dev-env
fi

failures=0
work=$(mktemp -d)

pass() { printf '  pass  %s\n' "$1"; }
fail() {
    printf '  FAIL  %s\n' "$1"
    failures=$((failures + 1))
}

# $1 description, $2 expected, $3 actual
check_eq() {
    if [ "$2" = "$3" ]; then
        pass "$1"
    else
        fail "$1 (expected [$2], got [$3])"
    fi
}

# $1 description, rest: command that must succeed
check_ok() {
    check_desc=$1
    shift
    if "$@" >/dev/null 2>&1; then
        pass "$check_desc"
    else
        fail "$check_desc"
    fi
}

# $1 description, rest: command that must fail
check_fails() {
    check_desc=$1
    shift
    if "$@" >/dev/null 2>&1; then
        fail "$check_desc"
    else
        pass "$check_desc"
    fi
}

section() { printf '\n--- %s\n' "$1"; }

# ---------------------------------------------------------------------------
section "fixtures"

# A plain file exactly where the repository wants to put a symlink. This is the
# case that separates a dotfiles installer from `ln -sf`.
mkdir -p "$HOME/.config/tmux"
printf 'set -g status off  # written by a human, before dev-env existed\n' \
    >"$HOME/.config/tmux/tmux.conf"

# A symlink that points somewhere else. It must be preserved too: the file it
# points at may be the only copy of something.
ln -sfn /dev/null "$HOME/.zshenv"

printf 'fixtures in place\n'

# ---------------------------------------------------------------------------
section "first bootstrap run"

# Not piped through tee: a pipeline would report tee's exit status and a failed
# bootstrap would look like a passing test.
if ! sh "$root/bootstrap.sh" >"$work/run1.log" 2>&1; then
    cat "$work/run1.log"
    printf '\nbootstrap.sh failed on the first run\n' >&2
    exit 1
fi
cat "$work/run1.log"

first_summary=$(grep '^summary:' "$work/run1.log")
first_changed=$(printf '%s' "$first_summary" | sed 's/^summary: changed=\([0-9]*\) .*/\1/')
printf '\n%s\n' "$first_summary"

if [ "$first_changed" -gt 0 ]; then
    pass "first run reported changes ($first_changed)"
else
    fail "first run reported no changes, so the counter proves nothing"
fi

# ---------------------------------------------------------------------------
section "existing files were preserved, not overwritten"

backup_root="$HOME/.local/state/dev-env/backups"
backup_dir=$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d | head -n 1)

check_eq "one backup directory was created" 1 \
    "$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

check_eq "the displaced tmux.conf kept its content" \
    'set -g status off  # written by a human, before dev-env existed' \
    "$(cat "$backup_dir/.config/tmux/tmux.conf" 2>/dev/null || true)"

check_eq "the displaced .zshenv symlink kept its target" /dev/null \
    "$(readlink "$backup_dir/.zshenv" 2>/dev/null || true)"

check_eq "the tmux config in HOME now points into the repository" \
    "$root/home/.config/tmux/tmux.conf" \
    "$(readlink "$HOME/.config/tmux/tmux.conf")"

check_eq "the ssh directory keeps mode 700" 700 "$(stat -c '%a' "$HOME/.ssh")"

# ---------------------------------------------------------------------------
section "zsh"

zsh_stderr=$(zsh -i -c exit 2>&1 >/dev/null || true)
check_eq "interactive zsh starts silently" '' "$zsh_stderr"

check_eq "ZDOTDIR points at the tracked configuration" \
    "$HOME/.config/zsh" "$(zsh -i -c 'print -rn -- $ZDOTDIR')"

check_ok "the completion system is initialised" \
    zsh -i -c '(( $+functions[compdef] )) || exit 1'

check_ok "zsh-autosuggestions is loaded" \
    zsh -i -c '(( $+functions[_zsh_autosuggest_start] )) || exit 1'

check_ok "zsh-syntax-highlighting is loaded" \
    zsh -i -c '(( $+functions[_zsh_highlight] )) || exit 1'

# zcompile runs in a detached job so that it never delays a prompt, so the
# bytecode appears shortly after a shell starts rather than during it.
zcompdump="$HOME/.cache/zsh/zcompdump-$(zsh -c 'print -rn -- $ZSH_VERSION')"
zsh -i -c exit
waited=0
while [ ! -s "$zcompdump.zwc" ] && [ "$waited" -lt 25 ]; do
    sleep 0.2
    waited=$((waited + 1))
done
check_ok "the completion dump is compiled to bytecode" test -s "$zcompdump.zwc"

check_eq "mkcd creates and enters a directory" "$work/mkcd-target" \
    "$(zsh -i -c "mkcd $work/mkcd-target >/dev/null && print -rn -- \$PWD")"

check_eq "up walks the requested number of levels" /usr \
    "$(zsh -i -c 'cd /usr/share/zsh && up 2 && print -rn -- $PWD')"

check_eq "history is kept out of \$HOME's top level" \
    "$HOME/.local/state/zsh/history" \
    "$(zsh -i -c 'print -rn -- $HISTFILE')"

# The whole point of the local.zsh pattern: it is sourced after everything the
# repository ships, so it wins.
printf 'export DEVENV_LOCAL_MARKER=applied\nalias ll="ls -l --literally-anything"\n' \
    >>"$HOME/.config/zsh/local.zsh"
check_eq "local.zsh overrides the tracked configuration" applied \
    "$(zsh -i -c 'print -rn -- $DEVENV_LOCAL_MARKER')"

# ---------------------------------------------------------------------------
section "neovim"

nvim_stderr=$(nvim --headless +qa 2>&1 >/dev/null || true)
check_eq "nvim loads the configuration without errors" '' "$nvim_stderr"

check_eq "options from config/options.lua are in effect" 4 \
    "$(nvim --headless -c 'lua io.write(vim.o.shiftwidth)' -c qa 2>/dev/null)"

check_eq "the leader key is set before plugins load" ' ' \
    "$(nvim --headless -c 'lua io.write(vim.g.mapleader)' -c qa 2>/dev/null)"

plugin_state=$(nvim --headless -c 'lua local t,p=0,0 for _,x in ipairs(require("lazy").plugins()) do t=t+1 if vim.uv.fs_stat(x.dir) then p=p+1 end end io.write(t.."/"..p)' -c qa 2>/dev/null)
plugin_total=${plugin_state%%/*}
check_eq "every plugin in the spec is on disk" "$plugin_total/$plugin_total" "$plugin_state"

check_ok "the spec contains more than one plugin" test "$plugin_total" -gt 1

check_eq "the lockfile pins every plugin in the spec" "$plugin_total" \
    "$(jq 'length' "$root/home/.config/nvim/lazy-lock.json")"

# The lockfile is an input to the bootstrap. If a run rewrote it, two machines
# bootstrapped a week apart would not be running the same plugin revisions.
check_ok "the bootstrap left the lockfile untouched" \
    cmp -s "$source_root/home/.config/nvim/lazy-lock.json" \
    "$root/home/.config/nvim/lazy-lock.json"

check_eq "the installed revision is the one in the lockfile" \
    "$(jq -r '."gitsigns.nvim".commit' "$root/home/.config/nvim/lazy-lock.json")" \
    "$(git -C "$HOME/.local/share/nvim/lazy/gitsigns.nvim" rev-parse HEAD)"

# Treesitter highlighting comes from the parsers Neovim ships with; no plugin
# compiles anything on this machine.
check_eq "bundled treesitter highlighting attaches to a lua buffer" true \
    "$(nvim --headless "$root/home/.config/nvim/init.lua" \
        -c 'lua io.write(tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil))' \
        -c qa 2>/dev/null)"

# ---------------------------------------------------------------------------
section "tmux"

tmux_socket=devenv-test
tmux_output=$(tmux -f "$HOME/.config/tmux/tmux.conf" -L "$tmux_socket" \
    new-session -d -s check 2>&1 || true)
check_eq "tmux parses the configuration without complaint" '' "$tmux_output"

check_eq "the escape-time fix is applied" 10 \
    "$(tmux -L "$tmux_socket" show -gv escape-time 2>/dev/null || true)"

check_eq "the prefix is rebound" C-a \
    "$(tmux -L "$tmux_socket" show -gv prefix 2>/dev/null || true)"

tmux -L "$tmux_socket" kill-server 2>/dev/null || true

# ---------------------------------------------------------------------------
section "git"

check_eq "git reads the tracked configuration" main \
    "$(git config --global --get init.defaultBranch)"

git init -q "$work/repo"
: >"$work/repo/file"
git -C "$work/repo" add file

# useConfigOnly means git must refuse to invent an identity here.
check_fails "git refuses to commit without an identity" \
    git -C "$work/repo" commit -m 'should not be possible'

cat >>"$HOME/.config/git/local.config" <<'IDENTITY'
[user]
    name = lpogosu
    email = 115780379+lpogosu@users.noreply.github.com
IDENTITY

check_ok "git commits once local.config supplies one" \
    git -C "$work/repo" commit -m 'now it works'

check_eq "the identity came from the machine-local file" lpogosu \
    "$(git -C "$work/repo" log -1 --format='%an')"

# ---------------------------------------------------------------------------
section "ssh"

check_eq "client defaults are applied" 'serveraliveinterval 30' \
    "$(ssh -G -T example.com | grep '^serveraliveinterval' || true)"

printf 'Host example.com\n    Port 2222\n' >>"$HOME/.ssh/config.d/00-local.conf"
check_eq "config.d wins over the tracked defaults" 'port 2222' \
    "$(ssh -G -T example.com | grep '^port' || true)"

# ---------------------------------------------------------------------------
section "generated files are in sync with the manifest"

check_ok "packages/*.txt and Brewfile match packages/manifest.tsv" \
    sh "$root/scripts/gen-packages.sh" --check

# ---------------------------------------------------------------------------
section "second bootstrap run"

if ! sh "$root/bootstrap.sh" >"$work/run2.log" 2>&1; then
    cat "$work/run2.log"
    printf '\nbootstrap.sh failed on the second run\n' >&2
    exit 1
fi
cat "$work/run2.log"

second_summary=$(grep '^summary:' "$work/run2.log")
printf '\n%s\n' "$second_summary"

check_eq "the second run changes nothing" 0 \
    "$(printf '%s' "$second_summary" | sed 's/^summary: changed=\([0-9]*\) .*/\1/')"

check_eq "the second run creates no new backup directory" 1 \
    "$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

# ---------------------------------------------------------------------------
section "zsh startup benchmark"

sh "$root/scripts/bench-zsh.sh"

# ---------------------------------------------------------------------------
printf '\n'
if [ "$failures" -eq 0 ]; then
    printf 'all checks passed\n'
    exit 0
fi
printf '%s check(s) failed\n' "$failures"
exit 1
