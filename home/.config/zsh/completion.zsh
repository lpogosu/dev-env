# Completion.
#
# compinit is the most expensive thing in a zsh startup: it stats every file in
# $fpath to decide whether the cached dump is still trustworthy, and $fpath on a
# machine with a few dozen packages is a few thousand files. The measured cost
# of doing that check on every prompt is in the README.
#
# So: run the full security check at most once a day, and load the cached dump
# directly the rest of the time.

autoload -Uz compinit

_devenv_zcompdump="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
mkdir -p "${_devenv_zcompdump:h}"

# (#qN.mh-24): exists, is a plain file, modified less than 24 hours ago.
if [[ -n $_devenv_zcompdump(#qN.mh-24) ]]; then
    compinit -C -d "$_devenv_zcompdump"
else
    compinit -d "$_devenv_zcompdump"
fi

# Compiling the dump to bytecode roughly halves the cost of loading it. Done in
# a detached subshell so it never delays the first prompt, and only when the
# bytecode is missing or older than the dump it was built from.
if [[ ! -s ${_devenv_zcompdump}.zwc || $_devenv_zcompdump -nt ${_devenv_zcompdump}.zwc ]]; then
    zcompile -R -- "$_devenv_zcompdump" &!
fi
unset _devenv_zcompdump

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'

# Case-insensitive, then partial-word, then substring — tried in that order, so
# an exact-case match is never shadowed by a fuzzier one.
zstyle ':completion:*' matcher-list \
    'm:{[:lower:]}={[:upper:]}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# The completion cache is for completers that shell out (dpkg, systemctl); it is
# not the zcompdump above.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# Never offer the current directory's own name after `cd ..`.
zstyle ':completion:*:cd:*' ignore-parents parent pwd
# Do not offer processes that are already this shell.
zstyle ':completion:*:*:kill:*:processes' command 'ps -u $USER -o pid,%cpu,cmd'
