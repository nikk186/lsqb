#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. mdb/vars.sh

ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"

if ${MILLENNIUMDB_REQUIRES_BUILD}; then
    echo -e "${ce}Error: Dependencies not build!${e}"
    exit 1
fi


# Execute queries
for query in ${MILLENNIUMDB_QUERIES}/q[0-9]*.query; do
    queryid=$(echo ${query} | grep -oP "[0-9]+(?=\.query)")
    echo "Query $queryid"
    outfile=${MILLENNIUMDB_OUTPUT}/out_${queryid}.txt
#    start=`date +%s.%N`
    (${MILLENNIUMDB_BINARIES}/query \
        --port ${MILLENNIUMDB_PORT} \
        < ${query}) > ${outfile}
#    end=`date +%s.%N`
    tail -4 ${outfile}
    echo ""

    threadcount="$(nproc) threads"
#    runtime=$(echo "$end - $start" | bc -l | awk '{printf "%f", $0}')
    runtime=$(tail -4 ${outfile} | sed -E "/^Execution time: [0-9\.]+ ms\.$/!d ; s/^Execution time: ([0-9\.]+) ms\.$/\1\/1000/g" | bc -l | awk '{printf "%f", $0}')
    result=$(tail -4 ${outfile} | sed -E "/^Found [0-9]+ results\.$/!d ; s/^Found ([0-9]+) results\.$/\1/g")
    echo -e "MillenniumDB\t${threadcount}\t${SF}\t${queryid}\t${runtime}\t${result}" >> ${RESULTS_FILE}
done

