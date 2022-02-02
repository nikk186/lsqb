#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. avg/vars.sh


if [[ ! -z $(which yum) ]]; then
    sudo yum update
    sudo yum install -y build-essential git clang-12 cmake default-jdk-headless g++ gcc pkg-config python3-minimal uuid-dev llvm-8 llvm-8-dev zlib1g-dev valgrind
elif [[ ! -z $(which apt) ]]; then
    sudo apt update
    sudo apt install -y build-essential git clang-12 cmake default-jdk-headless g++ gcc pkg-config python3-minimal uuid-dev llvm-8 llvm-8-dev zlib1g-dev valgrind
fi
