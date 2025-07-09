# History.

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000        # lines kept in memory
SAVEHIST=50000        # lines kept in the file
mkdir -p "${HISTFILE:h}" "$XDG_STATE_HOME/less"

setopt EXTENDED_HISTORY       # record the timestamp and duration of each command
setopt HIST_IGNORE_ALL_DUPS   # a repeated command replaces its older copy
setopt HIST_IGNORE_SPACE      # a leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # !! expands onto the line for review, does not run
setopt INC_APPEND_HISTORY     # write as commands finish, not only at exit

# SHARE_HISTORY is deliberately off. It imports other shells' commands into this
# shell's history on every prompt, so pressing Up in a long-running pane can
# yield a command typed in a different pane in a different directory. Appending
# incrementally gives the durability without the reordering: a new shell sees
# everything written so far, an existing shell keeps its own timeline.
setopt NO_SHARE_HISTORY
