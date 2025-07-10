#!/bin/sh
# Measure interactive zsh startup.
#
# What is measured: the wall time of `zsh -i -c exit`, which is rc parsing plus
# every module this repository sources. It is not prompt rendering — precmd
# hooks never run, because no prompt is ever drawn. That makes it the right
# number for "how long until I can type" and the wrong number for "how long
# between Enter and the next prompt".
#
# Four configurations are compared, so that each claim in the README has a
# figure attached rather than an adjective:
#
#   floor        an empty rc: what zsh itself costs on this machine
#   naive        the same modules, with compinit run in full on every start
#   no-plugins   the shipped configuration without zsh-autosuggestions and
#                zsh-syntax-highlighting
#   shipped      ~/.config/zsh as bootstrap.sh installs it
#
# The timing loop runs in zsh rather than in sh because $EPOCHREALTIME is
# available wherever zsh is, and `date +%s%N` is not (macOS).
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
runs=${RUNS:-50}
warmups=${WARMUPS:-5}

if ! command -v zsh >/dev/null 2>&1; then
    printf 'zsh is not installed\n' >&2
    exit 1
fi

# The loop itself. The outer zsh is started with -f so that its own startup is
# not part of what it measures. Single quotes on purpose: this is zsh source
# text, and nothing in it may be expanded by the sh that assembles it.
# shellcheck disable=SC2016
timing_loop='
    zmodload zsh/datetime
    repeat $WARMUPS zsh -i -c exit >/dev/null 2>&1
    start=$EPOCHREALTIME
    repeat $RUNS zsh -i -c exit >/dev/null 2>&1
    end=$EPOCHREALTIME
    printf "%.1f\n" $(( (end - start) * 1000.0 / RUNS ))
'

# $1 = ZDOTDIR for the shells being measured.
measure_variant() {
    RUNS="$runs" WARMUPS="$warmups" ZDOTDIR="$1" zsh -f -c "$timing_loop"
}

# No ZDOTDIR override: ~/.zshenv is what points zsh at the tracked
# configuration, and skipping it would measure something nobody runs.
measure_shipped() {
    RUNS="$runs" WARMUPS="$warmups" zsh -f -c "$timing_loop"
}

printf 'zsh %s, %s runs per configuration (%s warm-up runs discarded)\n\n' \
    "$(zsh -f -c 'print -rn -- $ZSH_VERSION')" "$runs" "$warmups"
printf '%-12s %10s\n' 'configuration' 'mean, ms'
printf '%-12s %10s\n' '------------' '--------'

for variant in floor naive no-plugins; do
    printf '%-12s %10s\n' "$variant" "$(measure_variant "$root/tests/bench/$variant")"
done
printf '%-12s %10s\n' 'shipped' "$(measure_shipped)"
