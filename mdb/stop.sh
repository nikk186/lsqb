#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. mdb/vars.sh

for session in $(screen -ls | grep -o "[0-9]*\.${MILLENNIUMDB_CONTAINER}"); do
    echo "Stopping ${session}"
    screen -S "${session}" -X quit || true
done
rm -rdf ${MILLENNIUMDB_GRAPH} > /dev/null 2>&1

exit 0
