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
    echo -e "${ce}AvantGraph is not yet installed. Installing now.${e}"
    avg/get.sh
fi

./avg/stop.sh
mkdir -p "${AVANTGRAPH_GRAPH}" "${AVANTGRAPH_PLANS}" "${AVANTGRAPH_OUTPUT}" "${AVANTGRAPH_CHECKSUMS}"
# Set correct owner if executed as root.
if [ "${USER}" == "root" ]; then
    sudo chown -R ${SUDO_USER}:${SUDO_USER} ${AVANTGRAPH_DIR}
fi

