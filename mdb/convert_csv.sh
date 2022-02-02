#!/bin/bash

b="\033[0;32m$(tput bold)"
bs="\033[0;32m"
ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"
es="\033[0m"

nodes=()
relations=()
outfile=""
append=false

for arg in "$@"; do
    if [[ "$arg" == "--nodes="* ]]; then
        node=${arg:8}
        if [[ "$node" =~ ^[A-Za-z][A-Za-z0-9_]*(:[A-Za-z][A-Za-z0-9_]*)*=[^=]+$ ]]; then
            nodes+=(${node})
        else
            echo -e "${ce}Invalid argument formatting: ${arg}${e}"
            echo -e "Use '--help' for more info."
            exit 1
        fi
    elif [[ "$arg" == "--relationships="*"="* ]]; then
        relation=${arg:16}
        if [[ "$relation" =~ ^[A-Za-z][A-Za-z0-9_]*(:[A-Za-z][A-Za-z0-9_]*)*=[^=]+$ ]]; then
            relations+=(${relation})
        else
            echo -e "${ce}Invalid argument formatting: ${arg}${e}"
            echo -e "Use '--help' for more info."
            exit 1
         fi
    elif [[ "$arg" == "-append" ]]; then
        append=true
    elif [[ "$arg" == "--help" ]]; then
        echo "USAGE: ./$(basename $0) [OPTIONS] outfile"
        echo "  --help                          Prints this help. Exists afterwards."
        echo "  --nodes=<N...>=<file>           Adds the given csv <file> to the graph. The nodes will have all the"
        echo "                                  labels <N>, using ':' as delimiter. Can be repeated."
        echo "  --relationships=<R...>=<file>   Adds the given csv <file> to the graph. The relations will have all"
        echo "                                  the labels <N>, using ':' as the delimiter. Can be repeated."
        echo "                                  the labels <N>, using ':' as the delimiter. Can be repeated."
        echo "  --append                        Appends the data to the file."
        echo ""
        exit 0
    else
        if [[ -z "$outfile" ]]; then
            outfile="$arg"
        else
            echo -e "${ce}Unknown argument: ${arg}${e}"
            echo "Use '--help' for more info."
            exit 1
        fi
    fi
done

if [[ -z "$outfile" ]]; then
    echo -e "${ce}Error: no output directory provided!${e}"
    echo "Use '--help' for more info."
    exit 2
fi

if ! $append ;then
    rm ${outfile} > /dev/null 2>&1
fi

echo -e "${b}Processing nodes${e}"
i=0
for node in "${nodes[@]}"; do
    split=($(echo ${node} | tr "=" " "))
    echo -e "${b}[$((++i))/${#nodes[@]}] ${bs}Processing node '${split[0]}'${es}"
    sed -E "/^[0-9]+$/!d ; s/^([0-9]+)$/N\1 :${split[0]/:/ :}/g" "${split[1]}" >> ${outfile}
done
echo ""

echo -e "${b}Processing relations${e}"
i=0
id=0
for relation in "${relations[@]}"; do
    split=($(echo ${relation} | tr "=" " "))
    echo -e "${b}[$((++i))/${#relations[@]}] ${bs}Processing relation '${split[0]/:/,}'${es}"
    rels=($(echo ${split[0]} | tr ":" " "))
    for rel in "${rels[@]}"; do
        sed -E "/^[0-9]+\|[0-9]+$/!d ; s/^([0-9]+)\|([0-9]+)$/N\1->N\2 :${rel} id:\"${rel}_N\1_N\2\"\nN\1->N\2 :${rel}_BI id:\"${rel}_N\1_N\2\"\nN\1<-N\2 :${rel}_BI id:\"${rel}_N\1_N\2\"/g" "${split[1]}" >> ${outfile}
    done
done


