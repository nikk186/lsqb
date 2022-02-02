#!/bin/bash

set -u

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

basedir=`pwd`
resultsdir="${basedir}/results"
resultsfile="${resultsdir}/results.csv"
minresultsfile="${resultsdir}/min-results.csv"
memfile="${resultsdir}/mem-results.csv"

cleanupscript="${basedir}/scripts/cleanup.sh"
memwatchscript="${basedir}/scripts/memwatcher.sh"
mingenscript="${basedir}/scripts/min_gen.sh"

b="\033[0;32m$(tput bold)"
bs="\033[0;32m"
ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"

sfavail=(example 0.003 0.1 0.3 1 3 10 30 100 300 1000 3000 10000 30000)
sfuse=()
dbsavail=(ddb:DuckDb pos:PostgreSQL mys:MySQL neo:Neo4j red:RedisGraph xgt:Trovares mem:Memgraph vos:Virtuoso avg:AvantGraph mdb:MillenniumDB)
dbsuse=()

# Check for help
for arg in "$@"; do
    if [[ "$arg" == "--help" ]] || echo "$arg" | grep -qE "^\-[^-]*h.*$"; then
        echo "USAGE: ./$(basename $0) [OPTIONS]"
        echo ""
        echo "  -h   --help             Displays this help and exits afterwards."
        echo "       --list-dbs         Prints all available databases and exists afterwards."
        echo "       --list-sf          Prints all available scale factors and exists afterwards."
        echo ""
        echo "       --sf=N1,...        Runs the benchmarks for the scale factors N1, etc. The values must be separated"
        echo "                          with ','. See '--list-sf' for the available values. The default is 'example'."
        echo "       --dbs=D1:N1,...    Sets the databases to use. The values must be separated with ','."
        echo "                          See '--list-dbs' for the default values."
        echo "  -a   --append           Appends the results instead of clearing them."
        echo "  -d   --no-docker-clear  Skips the docker clearing step."
        echo "  -i   --no-init          Skips the database initalisation step. Implicitly uses '--no-docker-clear'"
        echo "  -s   --no-stop          Skips stopping the databases afterwards."
        echo "  -rN  --repeat=N         The amount of times to repeat repeat each query."
        echo "  -m   --no-min-result    Do not generate the file '${minresultsfile}', containing the minimum run-times of each query"
        echo "                          for each DB."
        echo "  -M   --no-mem-track     Do not use the memory tracker. Th file ${memfile}' containing the maximum memory usages during"
        echo "                          the exeuction will not be generated."
        echo "  -u   --no-user          Does not wait for the user to view the settings."
        exit 0
    fi
done

append=0
cleandocker=1
doinit=1
dostop=1
repeat=1
user=1
genmin=1
genmem=1
for arg in "$@"; do
    if echo "$arg" | grep -qE "^\-[^\-].*$"; then
        if echo "$arg" | grep -qE "[^adisrmMuh0-9]$"; then
            echo -e "${ce}Unknown argument: '${arg}'${e}"
            echo "Use '--help' for more info."
            exit 1
        fi
        [[ "$arg" == *"a"* ]] && append=1
        [[ "$arg" == *"d"* ]] && cleandocker=0
        if [[ "$arg" == *"i"* ]]; then
            doinit=0
            cleandocker=0
        fi
        [[ "$arg" == *"s"* ]] && dostop=0
        if echo "$arg" | grep -q "r[1-9][0-9]*"; then
            repeat=$(echo "$arg" | sed -E "s/^\-[^-]*r([0-9]+)$/\1/g")
        fi
        [[ "$arg" == *"m"* ]] && genmin=0
        [[ "$arg" == *"M"* ]] && genmem=0
        [[ "$arg" == *"u"* ]] && user=0
    elif [[ "$arg" == "--sf="* ]]; then
        if ((${#sfuse[@]})); then
            echo -e "${ce}Cannot set scale factor twice!${e}"
            echo "Use '--help' for more info."
            exit 1
        fi
        sfuse=($(echo "${arg:5}" | tr "," " "))
    elif [[ "$arg" == "--dbs="* ]]; then
        if ((${#dbsuse[@]})); then
            echo -e "${ce}Cannot set databases twice!${e}"
            echo "Use '--help' for more info."
            exit 1
        fi
        dbsuse=($(echo "${arg:6}" | tr "," " "))
    elif [[ "$arg" == "--append" ]]; then
        append=1
    elif [[ "$arg" == "--no-docker-clear" ]]; then
        cleandocker=0
    elif [[ "$arg" == "--no-init" ]]; then
        doinit=0
        cleandocker=0
    elif [[ "$arg" == "--no-stop" ]]; then
        dostop=0
    elif echo "$arg" | grep -qE "^\-\-repeat=[1-9][0-9]*$"; then
        repeat=${arg:9}
    elif [[ "$arg" == "--no-min-result" ]]; then
        genmin=0
    elif [[ "$arg" == "--no-mem-track" ]]; then
        genmem=0
    elif [[ "$arg" == "--no-user" ]]; then
        user=0
    elif [[ "$arg" == "--list-dbs" ]]; then
        echo "Available databases:"
        echo $(echo "${dbsavail[@]}" | tr " " ",")
        exit 0
    elif [[ "$arg" == "--list-sf" ]]; then
        echo "Available scale factors:"
        echo $(echo "${sfavail[@]}" | tr " " ",")
        exit 0
    else
        echo -e "${ce}Unknown argument: '${arg}'${e}"
        echo "Use '--help' for more info."
        exit 1
    fi
done

# Verify SF values
if ((! ${#sfuse[@]})); then
    echo -e "${ce}No SF value given! Using 'example' instead.${e}"
    echo "Use '--help' for more info."
    sfuse=(example)
    echo ""
fi

if ((! ${#dbsuse})); then
    dbsuse=("${dbsavail[@]}")
fi

for sf in "${sfuse[@]}"; do
    if [[ ! " ${sfavail[*]} " =~ " ${sf} " ]]; then
        echo -e "${ce}Invalid scale factor: ${sf}!${e}"
        echo -e "Use '--list-sf' to list the available scale factors."
        echo "Use '--help' for more info."
        exit 3
    fi
done


# Show execution settings
echo -e "${b}====  EXECUTIUON  SETTINGS  ====${e}"
echo -n "Scaling factor(s): "; echo "${sfuse[@]}" | tr " " ","
echo -n "Database(s)      : "; echo "${dbsuse[@]}" | tr " " ","
echo -n "Append results   : "; ((${append})) && echo "yes" || echo "no"
echo -n "Clear containers : "; ((${cleandocker})) && echo "yes" || echo "no"
echo -n "Initialize DB(s) : "; ((${doinit})) && echo "yes" || echo "no"
echo -n "Stop DB(s)       : "; ((${dostop})) && echo "yes" || echo "no"
echo    "Repeat           : ${repeat}"
echo -n "Compute min      : "; ((${genmin})) && echo "yes" || echo "no"
echo -n "Track memory     : "; ((${genmem})) && echo "yes" || echo "no"
echo    "Execute dir      : ${basedir}/"
echo ""
if ((${user})); then
    echo "Continue? [Y/n]"
    read -rsn1 -t 20 res
    echo $res
    if [[ "$res" == "n" ]] || [[ "$res" == "N" ]]; then
        echo -e "${ce}User aborted!${e}"
        exit 4
    fi
fi

# Remove old results.
rm -f "${minresultsfile}"
if ((! ${append})); then
    rm -f "${resultsfile}" "${minresultsfile}" "${memfile}"
    touch "${resultsfile}" "${minresultsfile}" "${memfile}"
    # Set correct owner if executed as root.
    if [ "${USER}" == "root" ]; then
        sudo chown -R ${SUDO_USER}:${SUDO_USER} "${resultsfile}" "${minresultsfile}" "${memfile}"
    fi
fi

# Remove old containers (if any).
if ((${cleandocker})); then
    echo -e "${b}====  CLEANUP  OLD  DOCKER  CONTAINERS  ====${e}"
    dirs=()
    for db in ${dbsuse[@]}; do
        data=(${db//:/ })
        dirs+=("${data[0]}")
    done
    if (( ${#dirs[@]} )); then
        ${cleanupscript} "${dirs[@]}"
    fi
    echo ""
fi

# Start memory watcher (if needed).
if ((${genmem})); then
    trap "${memwatchscript} --stop" EXIT
    ${memwatchscript} --start
fi
# Execute benchmarks.
for sfidx in ${!sfuse[@]}; do
    export SF=${sfuse[$sfidx]}
    stepstr="($((sfidx+1))/${#sfuse[@]})"
    echo -e "${b}====  EXECUTE  BENCHMARKS  FOR  SF=${SF}  ${stepstr}  ====${e}"
    # Add memory results header.
    if ((${genmem})); then
        echo -n "SF${SF} (KiB)," >> "${memfile}"
        ((${doinit})) && echo  -n "Init," >> "${memfile}"
        for ((n=0; n < $repeat; n++)); do
            echo -n "Run $((n+1))," >> "${memfile}"
        done
        echo "" >> "${memfile}"
    fi

    for i in $(seq ${#dbsuse[@]}); do
        db="${dbsuse[$((i-1))]}"
        dbdata=(${db//:/ })
        dbname=${dbdata[1]}
        echo -e "${b}${stepstr}: [$i/${#dbsuse[@]}] ${bs}Executing benchmark for ${dbdata[1]}${e}"
        cd "$basedir/${dbdata[0]}"

        if ((${genmem})); then
            echo -n "${dbdata[1]}," >> "${memfile}"
            startmem=$(${memwatchscript} --reset --read)
        fi

        # Note: sudo needed for docker interactions.
        # Initialize DBs.
        if ((${doinit})); then
            sudo -E ./init-and-load.sh
            if ((${genmem})); then
                maxmem=$(${memwatchscript} --read)
                loadmem=$((maxmem - startmem))
                echo -n "${loadmem}," >> "${memfile}"
            fi
        fi
        if ((${genmem})); then
            endmem=$(${memwatchscript} --reset --read)
            initmem=$((endmem - startmem))
            ((initmem < 0)) && initmem=0
        fi

        # Run queries on DBs.
        for ((n=0; n < $repeat; n++)); do
            echo -e "${b}${stepstr}: [$i/${#dbsuse[@]}] ${bs}Run: $((n+1))/$repeat${e}"
            ((${genmem})) && startmem=$(${memwatchscript} --reset --read)
            sudo -E ./run.sh
            if ((${genmem})); then
                maxmem=$(${memwatchscript} --read)
                loadmem=$((initmem + maxmem - startmem))
                echo -n "${loadmem}," >> "${memfile}"
            fi
        done

        # Stop DBs.
        if ((${dostop})); then
            sudo -E ./stop.sh
            cntr=60
            while true; do
                if ! sudo docker ps -a | grep -qE "lsqb-${dbdata[0]}"; then
                    break;
                fi
                echo -e "${bs}Waiting for termination of docker container lsqb-${dbdata[0]}${e}"
                $((cntr--))
                if ((! ${cntr})); then
                    echo -e "${ce}Failed to terminate docker continer ${dbdata[0]}${e}"
                fi
                sleep 1
            done
        fi
        ((${genmem})) && echo "" >> "${memfile}"
        echo ""
    done
    if [[ $((sfidx+1)) != ${#sfuse[@]} ]]; then
        sleep 5
    fi
    echo ""
done

if ((${genmin})); then
    echo -e "${b}====  GENERATE  MIN  RESULTS  ====${e}"
    ${mingenscript}
fi

echo -e "${b}====  FINISHED  BENCHMARK  ====${e}"
