# Aliases.
#
# Only two kinds are here: a flag I always want, and a name that exists on one
# platform and not the other. Git shortcuts live in ~/.config/git/config as git
# aliases instead, so they also work over ssh and inside scripts.
#
# Not here on purpose: cp/mv/rm aliased to -i. An alias that adds a safety
# prompt on this machine trains the reflex of typing the command without the
# flag, which is exactly the reflex that deletes something on a machine where
# the alias is absent.

# Branch on $OSTYPE rather than probing `ls --color`: probing forks a process
# on every shell start to learn something that cannot change between starts.
if [[ $OSTYPE == darwin* ]]; then
    alias ls='ls -G'   # BSD ls has no --color
else
    alias ls='ls --color=auto --group-directories-first'
fi
alias ll='ls -lh'
alias la='ls -lAh'

alias grep='grep --color=auto'

alias ..='cd ..'
alias ...='cd ../..'

# Debian packages the binary as fdfind, because the name fd was already taken.
# Fedora and Homebrew install it as fd.
if (( ! $+commands[fd] )) && (( $+commands[fdfind] )); then
    alias fd=fdfind
fi

alias df='df -h'
alias du='du -h'
alias free='free -h'
