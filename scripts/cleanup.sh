#!/bin/bash

if [ $# -eq 0 ]; then
    dbdirs=(ddb pos mys neo red mem vos avg)
else
    dbdirs=("$@")
fi

for db in ${dbdirs[@]}; do
    sudo docker container stop "lsqb-${db}"
    sudo docker rm "lsqb-${db}"
done
