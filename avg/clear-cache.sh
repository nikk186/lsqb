#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. avg/vars.sh


b="\033[0;32m$(tput bold)"
ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"

if ((!${#@})); then
    echo -e "${ce}Expected at least 1 argument, but none found!${e}"
    exit 1
fi

all=0
sfs=()
for arg in "$@"; do
    if [[ "$arg" == "--all" ]]; then
        all=1
        break
    elif [[ "$arg" == "--sf="* ]]; then
        sfs=($(echo "${arg:5}" | tr "," " "))
    elif [[ "$arg" == "--help" ]]; then
        echo "USAGE: ./$(basename $0) [OPTIONS]"
        echo ""
        echo "  --help       Displays this help and exists afterwards."
        echo "  --all        Clears all cached files."
        echo "  --sf=N1,...  Clears the cache for the given scaling factors."
        echo "               Values must be separated with ','."
        exit 0
    else
        echo -e "${ce}Unknown argument: '${arg}'${e}"
        echo "Use '--help' for more info."
        exit 1
    fi
done

if ((${all})); then
    echo "Clearing all cache files!"
    rm -rdf ${AVANTGRAPH_CHECKSUMS}/*
    for file in ${AVANTGRAPH_DIR}/graph-data-*; do
        if [[ "$file" = "${AVANTGRAPH_DIR}/graph-data-*" ]]; then
            echo "No existing cache files found!"
            exit 0
        fi
        sf=$(echo "$file" | sed -E "s/^.*graph-data-([0-9a-zA-Z\.]+)$/\1/g")
        echo "Removing cache file for scaling factor '${sf}'."
        rm -rdf "$file"
    done
else
    for sf in "${sfs[@]}"; do
        echo "Removing cache file for scaling factor ${sf}."
        rm -rdf "${AVANTGRAPH_DIR}/graph-data-${sf}/"
        rm -rdf "${AVANTGRAPH_CHECKSUMS}/checklist_${sf}.chk"
    done
fi
