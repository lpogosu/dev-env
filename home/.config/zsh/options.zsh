# Shell options. Sourced first: EXTENDED_GLOB is needed by completion.zsh.

setopt EXTENDED_GLOB          # #, ~ and ^ in patterns, and the (#q...) qualifiers
setopt NO_CASE_GLOB           # matching a filename should not depend on shift keys
setopt GLOB_DOTS              # * matches dotfiles; this is a dotfiles repository
setopt NUMERIC_GLOB_SORT      # log10 sorts before log9, as a human would expect

setopt AUTO_CD                # a bare directory name means cd
setopt AUTO_PUSHD             # every cd pushes, so `cd -<Tab>` offers real history
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

setopt INTERACTIVE_COMMENTS   # # in an interactive line starts a comment
setopt LONG_LIST_JOBS
setopt NO_BEEP

# Zsh's default is to abort the whole command line when a glob matches nothing.
# That is right in scripts and wrong interactively: `git add *.py` in a
# directory without Python files should reach git and produce git's error, not
# a shell error that looks like a typo.
setopt NO_NOMATCH

# Do not let a background job outlive the shell silently, and do not kill it
# without asking either.
setopt CHECK_JOBS
setopt NO_HUP
