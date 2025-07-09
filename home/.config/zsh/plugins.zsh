# Plugins.
#
# Two of them, both installed as distribution packages, both sourced by
# absolute path. There is no plugin manager: a manager exists to clone, update
# and lazy-load a list of repositories, and for a list of length two, run by the
# distribution's own security updates, it is machinery in exchange for nothing.
#
# The order below is not a preference. zsh-syntax-highlighting wraps every ZLE
# widget that exists at the moment it is sourced, so anything that defines or
# rebinds a widget — including zsh-autosuggestions — has to be loaded before it.

_devenv_source_first() {
    local candidate
    for candidate in "$@"; do
        if [[ -r $candidate ]]; then
            source "$candidate"
            return 0
        fi
    done
    return 1
}

_devenv_brew_prefix=${HOMEBREW_PREFIX:-/opt/homebrew}

_devenv_source_first \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    "$_devenv_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# The default strategy replays the newest matching history entry. `completion`
# would also ask the completion system on every keystroke, which is the one
# thing that makes autosuggestions feel slow.
ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
bindkey '^ ' autosuggest-accept   # ctrl-space, because right-arrow also moves

_devenv_source_first \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    "$_devenv_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

unset _devenv_brew_prefix
unfunction _devenv_source_first
