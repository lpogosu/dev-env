# Key bindings.

bindkey -e   # emacs bindings; vi mode in the shell fights with vi mode in tmux copy mode

# Up and Down search history for lines starting with what is already typed, and
# leave the cursor at the end of the line rather than at column 0.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# terminfo is the correct source for these codes, but it is empty for TERM
# values the terminfo database does not know, and it reports the application-mode
# sequence while many terminals send the normal-mode one. Bind all three.
for _devenv_key in "${terminfo[kcuu1]}" '^[[A' '^[OA'; do
    [[ -n $_devenv_key ]] && bindkey "$_devenv_key" up-line-or-beginning-search
done
for _devenv_key in "${terminfo[kcud1]}" '^[[B' '^[OB'; do
    [[ -n $_devenv_key ]] && bindkey "$_devenv_key" down-line-or-beginning-search
done
unset _devenv_key

bindkey '^[[1;5C' forward-word     # ctrl-right
bindkey '^[[1;5D' backward-word    # ctrl-left
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Only / and the path separators break a word, so ctrl-w deletes one path
# component instead of the whole argument.
autoload -Uz select-word-style
select-word-style bash

# Edit the current command line in $EDITOR with ctrl-x ctrl-e.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Two fzf widgets, written here rather than sourced from fzf's own
# key-bindings.zsh.
#
# That file is not just longer than what it replaces — it snapshots the entire
# option set with `setopt` at the top and restores it through an `eval` at the
# bottom. In an interactive shell that has no terminal (`zsh -i -c ...` from a
# script, which is how the benchmark and the test suite start a shell) the
# restore tries to turn the `zle` option back on after startup, which zsh
# refuses, and every such shell prints a warning. Two widgets and one
# `command -v` do the same job with no vendored script and no surprises. The
# path it lives at also differs on every distribution, which was the other half
# of the problem.
if (( $+commands[fzf] )); then
    devenv-fzf-history() {
        local selected
        # -n suppresses the event numbers, so what comes back is the command
        # line itself and needs no parsing.
        selected=$(fc -rln 1 | fzf --no-sort --exact --height=40% --reverse \
            --query="$LBUFFER" --prompt='history> ') || return 0
        if [[ -n $selected ]]; then
            BUFFER=$selected
            CURSOR=$#BUFFER
        fi
        zle reset-prompt
    }
    zle -N devenv-fzf-history
    bindkey '^R' devenv-fzf-history

    devenv-fzf-file() {
        local -a lister
        if (( $+commands[fd] )); then
            lister=(fd --type f --hidden --exclude .git)
        elif (( $+commands[fdfind] )); then
            lister=(fdfind --type f --hidden --exclude .git)
        else
            lister=(find . -type f)
        fi
        local selected
        selected=$("${lister[@]}" 2>/dev/null | fzf --height=40% --reverse \
            --prompt='file> ') || return 0
        # (q) quotes the path, so a file name with a space arrives on the
        # command line as one argument.
        [[ -n $selected ]] && LBUFFER+="${(q)selected} "
        zle reset-prompt
    }
    zle -N devenv-fzf-file
    bindkey '^T' devenv-fzf-file
fi
