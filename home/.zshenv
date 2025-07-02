# The only file zsh reads from $HOME before it knows about ZDOTDIR, and it is
# read by every zsh — interactive, login, and the ones scripts spawn. So it
# holds exactly two things: where the rest of the configuration lives, and the
# environment that non-interactive shells also need.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# typeset -U makes `path` a unique array: re-sourcing this file, or nesting a
# login shell inside tmux inside a login shell, cannot produce a $PATH with the
# same directory three times.
typeset -U path PATH
path=("$HOME/.local/bin" /usr/local/bin $path)
export PATH

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
# -R keeps colour escapes, -F skips the pager for output that fits on a screen,
# -i is case-insensitive search unless the pattern has an uppercase letter.
export LESS='-R -F -i'
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# glibc has provided C.UTF-8 without any locale generation since 2.35, so this
# gives correct multibyte handling on a minimal container image where no
# locale package is installed at all. A real locale set by the desktop session
# always wins.
if [ -z "${LANG:-}" ]; then
    export LANG=C.UTF-8
fi
