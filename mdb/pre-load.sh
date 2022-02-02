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
    echo -e "${ce}Millennium DB is not yet installed. Installing now.${e}"
    mdb/get.sh
fi

mdb/stop.sh
rm -rdf "${MILLENNIUMDB_GRAPH}" "${MILLENNIUMDB_OUTPUT}" > /dev/null 2>&1
mkdir -p "${MILLENNIUMDB_GRAPH}" "${MILLENNIUMDB_OUTPUT}" "${MILLENNIUMDB_CHECKSUMS}" "${MILLENNIUMDB_CACHE_DIR}"
