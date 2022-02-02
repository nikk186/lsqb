#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. avg/vars.sh


if [[ "${AVANTGRAPH_CACHE}" == "1" ]]; then
    rm -rdf "${AVANTGRAPH_PLANS}"/* > /dev/null 2>&1
else
    rm -rdf "${AVANTGRAPH_GRAPH}"/* "${AVANTGRAPH_PLANS}"/* > /dev/null 2>&1
fi
