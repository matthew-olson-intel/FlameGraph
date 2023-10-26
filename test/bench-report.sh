#!/bin/bash
#
# bench-report.sh - View aggregated results of the performance of generating flamegraphs
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

mkdir -p ${BASEDIR}/bench-results

for i in "${!flame_opts[@]}"; do

  flame_opt="${flame_opts[i]}"
  config="${configs[i]}"
  
  outfile="${BASEDIR}/bench-results/${config}_times.txt"
  
  # Calculate arithmetic mean and variance from that mean.
  # Variance is calculated like:
  #   1. `ss` is the "sum of squares". Take the difference between
  #      each data point and the mean, and square it. Sum these up.
  #   2. `count` is the number of data points.
  #   3. Divide `ss` by `count`.
  real_avg=$(grep -P "^real" "${outfile}" | awk 'BEGIN{sum = 0; count = 0} {sum += $2; count++} END{printf "%.3f\n", sum/count}')
  real_var=$(grep -P "^real" "${outfile}" | \
                 awk -v avg="${real_avg}" \
                 'function abs(v) {return v<0?-v:v} BEGIN{ss = 0; count = 0;} {ss += abs($2-avg)^2; count++} END{printf "%.3f\n", ss/count}')
  
  echo "config: ${config}"
  echo "  avg: ${real_avg} ± ${real_var}"

done
