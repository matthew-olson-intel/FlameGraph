#!/bin/bash
#
# bench.sh - Measure the performance of generating flamegraphs
#
# This is used to detect performance regressions in the flamegraph software.
BASEDIR=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
set -euo pipefail

########################################
# User-editables
########################################
iters=10
flame_opts=( "" "--hash" "--md5hash" "--simplehash" "--bhash" "--b2hash" "--sumhash" "--xshash" )
configs=( "def" "hash" "md5hash" "simplehash" "bhash" "b2hash" "sumhash" "xshash" )

# We need to set TIMEFORMAT *before* starting a subshell
# that uses the BASH `time` builtin. The alternative to using
# subshells would be to rely on GNU time being installed, and
# using that instead.
export TIMEFORMAT=$'real %3R\nuser %3U\nsys %3S'

mkdir -p ${BASEDIR}/bench-results

# Artificially create a huge stackcollapse output
infile="${BASEDIR}/bench-results/input.txt"
perl -e 'for (;$i++<10000;) { for ($j=0;$j++<30;) { print "function_$i;" }; print " 1\n"; }' > "${infile}"

for i in "${!flame_opts[@]}"; do

  flame_opt="${flame_opts[i]}"
  config="${configs[i]}"
  
  # We're going to dump all `time` output into this file, per config
  outfile="${BASEDIR}/bench-results/${config}_times.txt"
  outflame="${BASEDIR}/bench-results/${config}_flame.svg"
  if [ -f "${outfile}" ]; then
    rm "${outfile}"
  fi
  
  # Drop caches, measure runtime three times
  for iter in $(seq ${iters}); do
    echo 3 | sudo tee /proc/sys/vm/drop_caches &> /dev/null
    ( time perl ${BASEDIR}/../flamegraph.pl ${flame_opt} "${infile}" > "${outflame}" 2>&1 ; ) 2>> "${outfile}"
  done
  
done
