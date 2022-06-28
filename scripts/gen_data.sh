#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

execdir=`pwd`
gendir=${execdir}/scratch/ldbc_snb_datagen_spark
convdir=${execdir}/scratch/ldbc_snb_data_converter
availsf=(example 0.003 0.1 0.3 1 3 10 30 100 300 1000 3000 10000 30000)

b="\033[0;32m$(tput bold)"
bs="\033[0;32m"
ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"
es="\033[0m"

user=1
sfuse=()
dobuild=0
preponly=0
memory=""
for arg in "$@"; do
    if [[ "$arg" == "--sf="* ]]; then
        if ((${#sfuse[@]})); then
            echo -e "${ce}Cannot set scale factor twice!${e}"
            echo "Use '--help' for more info."
            exit 1
        fi
        sfuse=($(echo "${arg:5}" | tr "," " "))
    elif [[ "$arg" == "--build" ]]; then
        dobuild=1
    elif [[ "$arg" == "--prep-only" ]]; then
        preponly=1
    elif [[ "$arg" == "--memory="* ]]; then
        memory="--memory ${arg:9}"
    elif [[ "$arg" == "--list-sf" ]]; then
        echo "Available scale factors:"
        echo "${availsf[@]}"
        exit 0
    elif [[ "$arg" == "--no-user" ]]; then
        user=0
    elif [[ "$arg" == "--help" ]]; then
        echo "USAGE: ./$(basename $0) [OPTIONS]"
        echo ""
        echo "  --help       Prints this help. Exits afterwards."
        echo "  --list-sf    Prints all available scale factors. Exists afterwards."
        echo "  --no-user    Doesn't wait for confirmation of the user after showing the execution settings."
        echo ""
        echo "  --sf=N1,...  Generates the data for the scale factors N1, etc. The values must be separated"
        echo "               with ','. See '--list-sf' for the available values. Must be provided."
        echo "  --build      (Re-)builds the data generator."
        echo "  --prep-only  Only prepares the data for benchmarking. Use this if the data is already available."
        echo "  --memory=M   The amount of memory used for data generation, e.g. 512m, 16g."
        exit 0
    else
        echo -e "${ce}Unknown argument: $arg${e}"
        echo "Use '--help' for more info."
        exit 1
    fi
done

if ((! ${preponly})) && ((! ${dobuild})); then
    # Force build when resources are not build.
    if [ ! -d ${gendir} ] && [ ! -d ${convdir} ]; then
        dobuild=1
    fi
fi

# Verify SF values.
if ((! ${#sfuse[@]})) && ((! ${dobuild})); then
    echo -e "${ce}No scale factor given!${e}"
    echo "Use '--help' for more info."
    exit 2
fi
for sf in "${sfuse[@]}"; do
    if [[ "${sf}" == "example" || "${sf}" == "0.003" ]]; then
        if ((! ${preponly})); then
            echo -e "${ce}The dataset '${sf}' must include the '--prep-only' option!${e}"
            exit 2
        fi
    fi

    if [[ ! " ${availsf[*]} " =~ " ${sf} " ]]; then
        echo -e "${ce}Invalid scale factor: ${sf}!${e}"
        echo -e "Use '--list-sf' to list the available scale factors."
        echo "Use '--help' for more info."
        exit 2
    fi
done

echo -e "${b}====  EXECUTION  SETTINGS  ====${e}"
echo -n "Scaling factor(s)   : "; echo "${sfuse[@]}" | tr " " ","
echo -n "Reserved memory     : "; [ "$memory" == "" ] && echo "default" || echo "${memory:9}"
echo -n "Only prepare data   : "; ((${preponly})) && echo "yes" || echo "no"
echo -n "Build data generator: "; ((${dobuild})) && echo "yes" || echo "no"
echo ""

if ((${user})); then
    echo "Continue? [Y/n]"
    read -n 1 -t 20 -rs var
    if [[ "${var}" == "n" || "${var}" == "N" ]]; then
        echo -e "${ce}Error: user abort!${e}"
        exit 3
    fi
fi

if ((${dobuild})); then
    echo -e "${b}====  BUILD  DATA  GENERATOR  AND  CONVERTER  ====${e}"
    echo -e "${bs}[1/4] Remove old data${e}"
    rm -rdf ${gendir} ${convdir} > /dev/null 2>&1

    echo -e "${bs}[2/4] Clone data gen + converter${e}"
    mkdir -p ${gendir} ${convdir}
    git clone https://github.com/ldbc/ldbc_snb_datagen_spark.git ${gendir}
    git clone https://github.com/ldbc/ldbc_snb_example_data.git ${convdir}

    echo -e "${bs}[3/4] Install spark hadoop${e}"
    curl https://downloads.apache.org/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz | sudo tar -xz -C /opt/

    # Build generator
    echo -e "${bs}[4/4] Build data generator${e}"
    cd "${gendir}"
    rm -rdf target > /dev/null 2>&1
    tools/build.sh
    echo ""
fi
export SPARK_HOME="/opt/spark-3.1.2-bin-hadoop3.2"
export PATH="$SPARK_HOME/bin":"$PATH"

for sfidx in ${!sfuse[@]}; do
    export SF=${sfuse[$sfidx]}
    stepstr="($((sfidx+1))/${#sfuse[@]})"

    if ((! ${preponly})); then
        echo -e "${b}====  GENERATE  DATA  FOR  SF=${SF}  ${stepstr}  ====${e}"
        cd "${gendir}"
        regex="ldbc_snb_datagen_([0-9\.]+_spark[0-9\.]+)-([0-9\.]+-SNAPSHOT)-jar-with-dependencies.jar"
        build_version_info=($(ls ${gendir}/target | sed -E "/${regex}/!d ; s/${regex}/\1 \2/g"))
        if ((${#build_version_info[@]} != 2)); then
            echo -e "${ce}No data generator version detected! Try to run with '--build'.${e}"
            echo "Use '--help' for more info."
            exit 4
        fi
        export PLATFORM_VERSION=${build_version_info[0]}
        export DATAGEN_VERSION=${build_version_info[1]}
        export DATAGEN_DATA_DIR="${gendir}/out/graphs/csv/raw/composite-merged-fk"
        echo -e "${bs}Remove old data${es}"
        rm -rdf ${gendir}/out > /dev/null 2>&1
        mkdir -p ${DATAGEN_DATA_DIR}

        echo -e "${bs}Generate data${es}"
        numcpu=$(grep -c ^processor /proc/cpuinfo)
        numcores=$(grep ^cpu\\scores /proc/cpuinfo | uniq | awk '{print $4}')
        tools/run.py ./target/ldbc_snb_datagen_${PLATFORM_VERSION}-${DATAGEN_VERSION}-jar-with-dependencies.jar \
            --cores ${numcpu} \
            --parallelism ${numcpu} \
            ${memory} \
            -- \
            --format csv \
            --mode raw \
            --scale-factor ${SF}
        echo ""

        echo -e "${b}====  CONVERT  DATA  FOR  SF=${SF}  ${stepstr}  ====${e}"
        echo -e "${b}${stepstr}: [1/8] ${bs}Clear old data${e}"
        cd "${convdir}"
        rm -rdf export/ data/ > /dev/null 2>&1
        git add export/ data/
        git checkout HEAD -- export/ data/

        echo -e "${b}${stepstr}: [2/8] ${bs}Concat data${e}"
        ./spark-concat.sh ${DATAGEN_DATA_DIR}

        echo -e "${b}${stepstr}: [3/8] ${bs}Load data${e}"
        ./load.sh ${DATAGEN_DATA_DIR} --no-header

        echo -e "${b}${stepstr}: [4/8] ${bs}Transform data${e}"
        ./transform.sh

        echo -e "${b}${stepstr}: [5/8] ${bs}Export projected data${e}"
        cat export/snb-export-only-ids-projected-fk.sql | ./duckdb ldbc.duckdb

        echo -e "${b}${stepstr}: [6/8] ${bs}Export merged data${e}"
        cat export/snb-export-only-ids-merged-fk.sql | ./duckdb ldbc.duckdb

        echo -e "${b}${stepstr}: [7/8] ${bs}Copy projected data${e}"
        rm -rdf "${execdir}/data/social-network-sf${SF}-projected-fk" > /dev/null 2>&1
        cp -r data/csv-only-ids-projected-fk/ "${execdir}/data/social-network-sf${SF}-projected-fk"

        echo -e "${b}${stepstr}: [8/8] ${bs}Copy merged data${e}"
        rm -rdf "${execdir}/data/social-network-sf${SF}-merged-fk" > /dev/null 2>&1
        cp -r data/csv-only-ids-merged-fk/ "${execdir}/data/social-network-sf${SF}-merged-fk"
        echo ""

    fi # ...if $preponly == 0

    # Prepare data
    echo -e "${b}====  PREPARE  DATA  FOR  BENCMARKS  FOR  SF=${SF}  ${stepstr}  ===="
    cd "${execdir}"
    echo -e "${b}${stepstr}: [1/4] ${bs}Generate headerless projected data${e}"
    for f in data/social-network-sf${SF}-projected-fk/*.csv; do tail -n +2 ${f} > ${f}-headerless; done

    echo -e "${b}${stepstr}: [2/4] ${bs}Generate headerless merged data${e}"
    for f in data/social-network-sf${SF}-merged-fk/*.csv; do tail -n +2 ${f} > ${f}-headerless; done

    echo -e "${b}${stepstr}: [3/4] ${bs}Fixup projected header data${e}"
    for file in ${execdir}/data/social-network-sf${SF}-projected-fk/*.csv; do
        name=$(basename $file | sed -E "s/^(.*)\\.csv$/\1/")
        if [[ "$name" == *"_"* ]]; then
            # Edge/Relation
            id1=$(echo $name | sed -E "s/^(.*)_(.*)_(.*)$/\1/")
            id2=$(echo $name | sed -E "s/^(.*)_(.*)_(.*)$/\3/")
            sed "1 s/.*/:START_ID(${id1})|:END_ID(${id2})/" "${file}" > "${file}.tmp"
        else
            # Node/ID
            sed "1 s/.*/id:ID(${name})/" "${file}" > "${file}.tmp"
        fi
        mv "${file}.tmp" "${file}"
    done

    echo -e "${b}${stepstr}: [4/4] ${bs}Generate ntriples${e}"
    ./scripts/convert-to-ntriples.sh
    echo ""
done
