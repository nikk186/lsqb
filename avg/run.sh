#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. avg/vars.sh

ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"

if ${AVANTGRAPH_REQUIRES_BUILD}; then
    echo -e "${ce}Error: Dependencies not build!${e}"
    exit 1
fi


# Copy plans to use (temporary)
rm -rdf ${AVANTGRAPH_PLANS}
mkdir ${AVANTGRAPH_PLANS}
cp ${AVANTGRAPH_SRC_PLANS}/* ${AVANTGRAPH_PLANS}/


if [[ "${AVANTGRAPH_PUSHDOWN}" == "1" ]]; then
    EXEC_FILE=${AVANTGRAPH_BINARIES}/ag-exec-multi-threaded
else
    EXEC_FILE=${AVANTGRAPH_BINARIES}/no-pushdown/ag-exec-multi-threaded
fi

# Execute queries
for plan in ${AVANTGRAPH_PLANS}/*.plan.ipr; do
    queryid=$(echo ${plan} | grep -oP "[0-9]+(?=\.plan\.ipr)")
    outfile=${AVANTGRAPH_OUTPUT}/out_${queryid}.txt
    tracefile=${AVANTGRAPH_OUTPUT}/trace_${queryid}.txt

#    start=`date +%s.%N`
    (${EXEC_FILE} \
        --planner none \
        --count \
        -M \
        --timeout=300 \
        --trace-filters=main \
        --trace-output="${tracefile}" \
        `#--verbose` \
        `#--dump-execution-state` \
        ${AVANTGRAPH_GRAPH}/ \
        ${plan} || true) |& tee ${outfile}
#    end=`date +%s.%N`

    threadcount="$(nproc) threads"
#    runtime=$(echo "$end - $start" | bc -l | awk '{printf "%f", $0}')
    runtime=$(cat "${tracefile}" | sed -E "/^\{\"name\": \"printQueryResults\"/!d ; s/^.*\"dur\": ([1-9][0-9]*).*$/\1 \/ 1000000/g" | bc -l | awk '{printf "%f", $0}')
    result=$(sed -E "/^Count [0-9]+$/!d ; s/^Count ([0-9]+)$/\1/g" ${outfile})
    if [[ "${result}" == "" ]]; then
        exit 1
    fi
    echo -e "AvantGraph\t${threadcount}\t${SF}\t${queryid}\t${runtime}\t${result}" >> ${RESULTS_FILE}
done
