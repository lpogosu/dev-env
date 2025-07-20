# The shipped configuration minus plugins.zsh, and nothing else.
#
# The difference between this and "shipped" is the price of zsh-autosuggestions
# and zsh-syntax-highlighting, which is the number that decides whether keeping
# them is worth it.

shipped=${DEVENV_ZSH_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}

for module in options history completion keys prompt aliases functions; do
    source "$shipped/$module.zsh"
done

unset module shipped
