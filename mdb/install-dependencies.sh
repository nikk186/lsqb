#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

if [[ ! -z $(which yum) ]]; then
    sudo yum update
    sudo yum install -y git g++ cmake libboost-all-dev screen
elif [[ ! -z $(which apt) ]]; then
    sudo apt update
    sudo apt install -y git g++ cmake libboost-all-dev screen
fi
