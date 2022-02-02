#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. mdb/vars.sh


red='\033[0;31m'
green='\033[0;32m'
end='\033[0m'

# Start server.
screen -DmS ${MILLENNIUMDB_CONTAINER} ${MILLENNIUMDB_BINARIES}/server \
    --db-folder ${MILLENNIUMDB_GRAPH} \
    --port ${MILLENNIUMDB_PORT} \
    --timeout ${MILLENNIUMDB_TIMEOUT} \
    --buffer-size ${MILLENNIUMDB_BUFFER_SIZE} \
    --private-buffer-size ${MILLENNIUMDB_PRIVATE_BUFFER_SIZE} \
    --max-threads $(nproc) &

# Wait for initialization of server.
echo -ne "${red}Initializing Millennium DB"
while true; do
    res=$(echo "SELECT * MATCH (:None) LIMIT 0" | ${MILLENNIUMDB_BINARIES}/query --port ${MILLENNIUMDB_PORT} || true)
    if [[ ! $res == "Error connecting to server: connect: Connection refused" ]]; then
        echo -e "\n${green}Millennium DB initialized!${end}"
        break
    fi
    echo -ne ". "
    sleep 1
done
