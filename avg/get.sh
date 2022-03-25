#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. avg/vars.sh

cd avg


b="\033[0;32m$(tput bold)"
bs="\033[0;32m"
ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"
user=$([ "${USER}" == "root" ] &&  echo "${SUDO_USER}" || echo "${USER}")

agdir="${AVANTGRAPH_DIR}/avantgraph"
builddir="${agdir}/cmake-build-performance"

if ((! ${#@})); then
    echo "This repo is currently private! If you are not authorized, you cannot clone and build it. Attempting to build it will remove the binaries present in '${AVANTGRAPH_BINARIES}'."
    echo "Provide any argument to prevent this message."
    echo "Continue? [y/N]"
    read -t 20 -n 1 -rs res
    if ! [[ "${res}" == "y" || "${res}" == "Y" ]]; then
        echo -e "${ce}Error: User abort!${e}"
        exit 1
    fi
fi

echo -e "${b}[1/8] Installing dependencies${e}"
sudo ./install-dependencies.sh
echo -e "${b}Done${e}\n"

echo -e "${b}[2/8] Clearing old data${e}"
sudo rm -rdf ${AVANTGRAPH_DIR} ${AVANTGRAPH_BINARIES} > /dev/null 2>&1
sudo -u "${user}" mkdir -p ${AVANTGRAPH_DIR} ${AVANTGRAPH_BINARIES} ${agdir}
echo -e "${b}Done${e}\n"

echo -e "${b}[3/8] Cloning AvantGraph benchmark repo${e}"
sudo -u "${user}" git clone -b kaj/benchmark ssh://git@git.avantgraph.io:2222/ag/avantgraph.git "${agdir}"
cd "${agdir}"
echo -e "${b}Done${e}\n"

echo -e "${b}[4/8] Building AvantGraph benchmark${e}"
sudo -u "${user}" cmake -DCMAKE_BUILD_TYPE=Release -S "${agdir}" -B "${builddir}"
sudo -u "${user}" cmake --build "${builddir}" --target avantgraph ag-load-graph ag-index ag-plan ag-exec-multi-threaded -- -j $(nproc)
echo -e "${b}Done${e}\n"

echo -e "${b}[5/8] Installing AvantGraph benchmark${e}"
sudo -u "${user}" cp "${builddir}/src/tools/load-graph/ag-load-graph" "${AVANTGRAPH_BINARIES}/ag-load-graph"
sudo -u "${user}" cp "${builddir}/src/tools/index/ag-index" "${AVANTGRAPH_BINARIES}/ag-index"
sudo -u "${user}" cp "${builddir}/src/tools/plan/ag-plan" "${AVANTGRAPH_BINARIES}/ag-plan"
sudo -u "${user}" cp "${builddir}/src/tools/execMultiTreaded/ag-exec-multi-threaded" "${AVANTGRAPH_BINARIES}/ag-exec-multi-threaded"
sudo -u "${user}" mkdir -p "${AVANTGRAPH_BINARIES}/contrib"
sudo -u "${user}" cp "${agdir}/contrib/import_csv.py" "${AVANTGRAPH_BINARIES}/contrib/import_csv.py"
echo -e "${b}Done${e}\n"

echo -e "${b}[6/8] Checking out AvantGraph benchmark-no-pushdown${e}"
sudo -u "${user}" git checkout kaj/benchmark-no-pushdown
echo -e "${b}Done${e}"

echo -e "${b}[7/8] Building AvantGraph benchmark-no-pushdown${e}"
sudo -u "${user}" cmake -DCMAKE_BUILD_TYPE=Release -S "${agdir}" -B "${builddir}"
sudo -u "${user}" cmake --build "${builddir}" --target avantgraph ag-load-graph ag-index ag-plan ag-exec-multi-threaded -- -j $(nproc)
echo -e "${b}Done${e}\n"

echo -e "${b}[8/8] Installing AvantGraph benchmark-no-pushdown${e}"
sudo -u "${user}" mkdir -p "${AVANTGRAPH_BINARIES}/no-pushdown"
sudo -u "${user}" cp "${builddir}/src/tools/plan/ag-plan" "${AVANTGRAPH_BINARIES}/no-pushdown/ag-plan"
sudo -u "${user}" cp "${builddir}/src/tools/execMultiTreaded/ag-exec-multi-threaded" "${AVANTGRAPH_BINARIES}/no-pushdown/ag-exec-multi-threaded"
echo -e "${b}Done${e}\n"
