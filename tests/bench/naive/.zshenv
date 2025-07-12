# The benchmark points ZDOTDIR at this directory, and zsh then reads this file
# instead of ~/.zshenv. Load the real one so the variant starts from the same
# environment as the shipped configuration, then take ZDOTDIR back.
_bench_zdotdir=$ZDOTDIR
source "$HOME/.zshenv"
ZDOTDIR=$_bench_zdotdir
unset _bench_zdotdir
