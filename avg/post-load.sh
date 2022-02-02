#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. avg/vars.sh


# Set correct owner if executed as root.
if [ "${USER}" == "root" ]; then
    sudo chown -R ${SUDO_USER}:${SUDO_USER} ${AVANTGRAPH_DIR}
fi
