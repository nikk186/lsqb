#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. red/vars.sh

mkdir -p ${REDISGRAPH_SCRATCH_DIR}
red/stop.sh
sudo rm -rdf ${REDISGRAPH_SCRATCH_DIR} > /dev/null 2>&1
mkdir ${REDISGRAPH_SCRATCH_DIR}

sudo mkdir -p ${REDISGRAPH_SCRATCH_DIR}
# Set correct owner
if [ "${USER}" == "root" ]; then
    sudo chown -R ${SUDO_USER}:${SUDO_USER} ${REDISGRAPH_SCRATCH_DIR}
else
    sudo chown -R ${USER}:${USER} ${REDISGRAPH_SCRATCH_DIR}
fi

red/start.sh
python3 red/del-db.py
