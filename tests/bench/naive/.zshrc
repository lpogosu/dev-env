# The same configuration written the obvious way.
#
# Exactly one thing differs from the shipped configuration: compinit runs its
# full security check on every start and the resulting dump is never compiled.
# That is the line almost every hand-written zshrc contains, and the benchmark
# exists to put a number on it.
#
# The completion zstyles from completion.zsh are not repeated here; they are
# assignments and cost nothing measurable.

shipped=${DEVENV_ZSH_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}

source "$shipped/options.zsh"
source "$shipped/history.zsh"

autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-naive-$ZSH_VERSION"

source "$shipped/keys.zsh"
source "$shipped/prompt.zsh"
source "$shipped/aliases.zsh"
source "$shipped/functions.zsh"
source "$shipped/plugins.zsh"

unset shipped
