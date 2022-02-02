#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. mdb/vars.sh

cd mdb


b="\033[0;32m$(tput bold)"
e="\033[0m$(tput sgr0)"
user=$([ "${USER}" == "root" ] &&  echo "${SUDO_USER}" || echo "${USER}")

mdbdir="${MILLENNIUMDB_DIR}/MillenniumDB"
builddir="${mdbdir}/build"

# Install dependencies
echo -e "${b}[1/5] Installing dependencies${e}"
sudo ./install-dependencies.sh
echo -e "${b}Done${e}\n"

# Clear old data
echo -e "${b}[2/5] Clearing old data${e}"
sudo rm -rdf  ${MILLENNIUMDB_DIR} ${MILLENNIUMDB_BINARIES} > /dev/null 2>&1
sudo -u "$user" mkdir -p ${MILLENNIUMDB_DIR} ${MILLENNIUMDB_BINARIES} ${mdbdir}
echo -e "${b}Done${e}\n"

# Clone repo
echo -e "${b}[3/5] Cloning repo${e}"
sudo -u "$user" git clone https://github.com/MillenniumDB/MillenniumDB.git "${mdbdir}"
echo -e "${b}Done${e}\n"

# Build
echo -e "${b}[4/5] Building MillenniumDB${e}"
sudo -u "$user" cmake -DCMAKE_BUILD_TYPE=Release -S "${mdbdir}" -B "${builddir}"
sudo -u "$user" cmake --build "${builddir}" -- -j $(nproc)
echo -e "Done\n"

# Install
echo -e "${b}[5/5] Installing MillenniumDB${e}"
sudo -u "$user" cp ${builddir}/bin/{create_db,server,query} ${MILLENNIUMDB_BINARIES}/
echo -e "${b}Done\n"
