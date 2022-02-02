#!/bin/bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

basedir=`pwd`
user=$([ "${USER}" == "root" ] &&  echo "${SUDO_USER}" || echo "${USER}")

rm -f "${basedir}/results/min-results.csv"
declare -A db_value
declare -A db_str
while read line; do
    key=$(echo "${line}" | sed -E "s/^([^\t]+)\t([^\t]*)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)$/\3_\1_\4/g")
    value=$(echo "${line}" | sed -E "s/^([^\t]+)\t([^\t]*)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)$/\5/g")
    if [[ -z ${db_value["${key}"]} ]] || [[ $(echo "if ($value<${db_value[${key}]}) 1 else 0" | bc) == 1 ]]; then
        db_value["${key}"]="${value}"
        db_str["${key}"]="${line}"
    fi
done < "${basedir}/results/results.csv"
IFS=$'\n'; sorted_keys=($(sort <<<${!db_str[*]})); unset IFS
for key in "${sorted_keys[@]}"; do
    echo "${db_str[$key]}" >> "${basedir}/results/min-results.csv"
done

# Set correct owner if executed as root.
if [ "${USER}" == "root" ]; then
    sudo chown -R ${SUDO_USER}:${SUDO_USER} "${basedir}/results/min-results.csv"
fi
