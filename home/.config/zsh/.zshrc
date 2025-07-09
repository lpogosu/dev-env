# Interactive shell configuration.
#
# No framework. The modules below are sourced in a fixed order and the order is
# load-bearing twice: options.zsh must come first because later files use
# extended globbing, and plugins.zsh must come last because zsh-syntax-
# highlighting wraps every ZLE widget that exists at the moment it is sourced.

for _devenv_module in options history completion keys prompt aliases functions plugins; do
    source "$ZDOTDIR/$_devenv_module.zsh"
done
unset _devenv_module

# Machine-local overrides, created empty by bootstrap.sh and never tracked.
# Sourced last so it can override anything above.
[[ -r $ZDOTDIR/local.zsh ]] && source "$ZDOTDIR/local.zsh"
