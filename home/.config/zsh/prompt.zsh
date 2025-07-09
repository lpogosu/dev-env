# Prompt.
#
# Two lines of information and nothing else: where I am, which branch, and
# whether the last command failed. Everything a prompt shows costs work on every
# single Enter, so each element has to be worth that.

autoload -Uz vcs_info add-zsh-hook
setopt PROMPT_SUBST

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{yellow}%b%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}%b%f %F{red}(%a)%f'

# check-for-changes is off on purpose. It runs the equivalent of `git status`
# before every prompt; in a repository with a large working tree that is tens of
# milliseconds of disk work to render one asterisk. The branch name answers the
# question that actually matters mid-command ("am I on the right branch"), and
# `git status` answers the other one when it is asked.
zstyle ':vcs_info:git:*' check-for-changes false

add-zsh-hook precmd vcs_info

# %(?..X) renders X only when the previous command failed, so a successful
# prompt carries no exit-status noise at all.
PROMPT='%F{blue}%~%f${vcs_info_msg_0_} %(?..%F{red}%?%f )%(!.%F{red}#%f.$) '

# The right-hand prompt disappears while a command line is being edited, so it
# is the correct place for context that is nice to have and never in the way.
RPROMPT='%F{242}%n@%m%f'
