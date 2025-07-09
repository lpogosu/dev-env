# Shell functions.
#
# The bar for adding one: it has to do something an alias cannot (take an
# argument in the middle, change the shell's own state, or branch), and it has
# to be something I reach for more than once a week. Five have cleared it.

# Create a directory and enter it. The one-liner everyone types by hand, and the
# only reason `mkdir foo` and `cd foo` are two commands.
mkcd() {
    if (( $# != 1 )); then
        print -u2 'usage: mkcd <directory>'
        return 2
    fi
    mkdir -p -- "$1" && cd -- "$1"
}

# Go up N levels. `up 3` beats `cd ../../..` because miscounting dots is silent
# and miscounting a number is not.
up() {
    local levels=${1:-1}
    if [[ ! $levels =~ '^[0-9]+$' ]]; then
        print -u2 'usage: up [levels]'
        return 2
    fi
    local target=.
    repeat "$levels" target+=/..
    cd -- "$target"
}

# Clone into a path derived from the URL and enter it, so every checkout on the
# machine is at ~/src/<host>/<owner>/<repo> and nothing depends on which
# directory the clone was started from.
gclone() {
    if (( $# != 1 )); then
        print -u2 'usage: gclone <repository-url>'
        return 2
    fi
    local url=$1
    # Both forms in one substitution: git@host:owner/repo.git and
    # https://host/owner/repo.git.
    local slug=${${url#*://}/:/\/}
    slug=${slug#*@}
    slug=${slug%.git}
    local target=$HOME/src/$slug
    if [[ -d $target ]]; then
        print -u2 "already cloned: $target"
        cd -- "$target"
        return 0
    fi
    git clone -- "$url" "$target" && cd -- "$target"
}

# Serve the current directory over HTTP. For looking at a build output or
# handing a colleague a file, not for anything that should stay up.
serve() {
    local port=${1:-8000}
    print -r -- "serving $PWD on http://127.0.0.1:$port"
    python3 -m http.server --bind 127.0.0.1 "$port"
}

# A dated scratch directory under ~/scratch, created and entered. Stops
# throwaway work from accumulating in $HOME or in a real repository, and the
# date in the name makes "delete everything older than a month" a one-liner.
scratch() {
    local name=${1:-$(date +%H%M%S)}
    local dir=$HOME/scratch/$(date +%Y-%m-%d)/$name
    mkdir -p -- "$dir" && cd -- "$dir"
}
