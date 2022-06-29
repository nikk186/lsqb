#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. avg/vars.sh

if ${AVANTGRAPH_REQUIRES_BUILD}; then
    exit 1
fi


bc="\033[0;33m$(tput bold)"
c="\033[0;33m"
ebc="\033[0m$(tput sgr0)"

loadtime=0
indextime=0

if ((${AVANTGRAPH_CACHE})) && [[ $(md5sum -c "${AVANTGRAPH_CHECKSUMS}/checklist_${SF}.chk" > /dev/null 2>&1; echo $?) == 0 ]]; then
    echo "Using cached graph!"
else
    if ((${AVANTGRAPH_CACHE})); then
        echo "No cached graph found, generating from scratch..."
    fi

    # Load graph
    start=`date +%s.%N`

    BASE=${IMPORT_DATA_DIR_PROJECTED_FK}
    TARGET=${AVANTGRAPH_GRAPH}

    # Remove old data.
    sudo rm -rdf "${TARGET}"
    mkdir -p "${TARGET}"

    ## Load using N-triples
    ## Note: the generated N-triples by lsqb are invalid (< and > brackets are missing for 2nd value).
    #${AVANTGRAPH_BINARIES}/ag-load-graph \
    #    --graph-format=ntriple \
    #    --validate-iris=false \
    #    --report-progress \
    #    ${LSQB_NT_FILE} \
    #    ${TARGET}/

    ${AVANTGRAPH_BINARIES}/ag-load-graph \
        --graph-format=json \
        --validate-iris=false \
        --report-progress <(python3 ${AVANTGRAPH_LOAD_SCRIPT} \
            --nodes=City="${BASE}/City.csv" \
            --nodes=Company="${BASE}/Company.csv" \
            --nodes=Country="${BASE}/Country.csv" \
            --nodes=Continent="${BASE}/Continent.csv" \
            --nodes=Forum="${BASE}/Forum.csv" \
            --nodes=Message:Comment="${BASE}/Comment.csv" \
            --nodes=Message:Post="${BASE}/Post.csv" \
            --nodes=Person="${BASE}/Person.csv" \
            --nodes=Tag="${BASE}/Tag.csv" \
            --nodes=TagClass="${BASE}/TagClass.csv" \
            --nodes=University="${BASE}/University.csv" \
            --relationships=CONTAINER_OF="${BASE}/Forum_containerOf_Post.csv" \
            --relationships=HAS_CREATOR="${BASE}/Comment_hasCreator_Person.csv" \
            --relationships=HAS_CREATOR="${BASE}/Post_hasCreator_Person.csv" \
            --relationships=HAS_INTEREST="${BASE}/Person_hasInterest_Tag.csv" \
            --relationships=HAS_MEMBER="${BASE}/Forum_hasMember_Person.csv" \
            --relationships=HAS_MODERATOR="${BASE}/Forum_hasModerator_Person.csv" \
            --relationships=HAS_TAG="${BASE}/Comment_hasTag_Tag.csv" \
            --relationships=HAS_TAG="${BASE}/Forum_hasTag_Tag.csv" \
            --relationships=HAS_TAG="${BASE}/Post_hasTag_Tag.csv" \
            --relationships=HAS_TYPE="${BASE}/Tag_hasType_TagClass.csv" \
            --relationships=IS_LOCATED_IN="${BASE}/Comment_isLocatedIn_Country.csv" \
            --relationships=IS_LOCATED_IN="${BASE}/Company_isLocatedIn_Country.csv" \
            --relationships=IS_LOCATED_IN="${BASE}/Person_isLocatedIn_City.csv" \
            --relationships=IS_LOCATED_IN="${BASE}/Post_isLocatedIn_Country.csv" \
            --relationships=IS_LOCATED_IN="${BASE}/University_isLocatedIn_City.csv" \
            --relationships=IS_PART_OF="${BASE}/City_isPartOf_Country.csv" \
            --relationships=IS_PART_OF="${BASE}/Country_isPartOf_Continent.csv" \
            --relationships=IS_SUBCLASS_OF="${BASE}/TagClass_isSubclassOf_TagClass.csv" \
            --relationships=KNOWS="${BASE}/Person_knows_Person.csv" \
            --relationships=LIKES="${BASE}/Person_likes_Comment.csv" \
            --relationships=LIKES="${BASE}/Person_likes_Post.csv" \
            --relationships=REPLY_OF="${BASE}/Comment_replyOf_Comment.csv" \
            --relationships=REPLY_OF="${BASE}/Comment_replyOf_Post.csv" \
            --relationships=STUDY_AT="${BASE}/Person_studyAt_University.csv" \
            --relationships=WORK_AT="${BASE}/Person_workAt_Company.csv" \
            --delimiter '|') \
        ${TARGET}/
    end=`date +%s.%N`
    loadtime=$(echo "$end - $start" | bc -l | awk '{printf "%f", $0}')

    # Make index(es) TODO
    start=`date +%s.%N`
    #${AVANTGRAPH_BINARIES}/ag-index create --type=label-adjacency:multimap ${AVANTGRAPH_GRAPH}
    end=`date +%s.%N`
    indextime=$(echo "$end - $start" | bc -l | awk '{printf "%f", $0}')

    if ((${AVANTGRAPH_CACHE})); then
        echo "Computing checksum..."
        find ${BASE}/* -type f -exec md5sum "{}" + > "${AVANTGRAPH_CHECKSUMS}/checklist_${SF}.chk"
        find ${TARGET}/* -type f -exec md5sum "{}" + >> "${AVANTGRAPH_CHECKSUMS}/checklist_${SF}.chk"
    fi
fi

# Plan queries
start=`date +%s.%N`
## Copy queries
#cp -r ${AVANTGRAPH_SRC_QUERIES}/*.cypher ${AVANTGRAPH_QUERIES}/ > /dev/null 2>&1
## Generate plans
#for query in ${AVANTGRAPH_QUERIES}/*.cypher; do
#    ${AVANTGRAPH_BINARIES}/ag-plan --query-type=cypher --planner=wco --count --verbose ${AVANTGRAPH_GRAPH} ${query}
#done

## Copy plans (tmp)
mkdir -p ${AVANTGRAPH_PLANS}
cp -r ${AVANTGRAPH_SRC_PLANS}/*.plan.ipr ${AVANTGRAPH_PLANS}/ > /dev/null 2>&1
end=`date +%s.%N`
plantime=$(echo "$end - $start" | bc -l | awk '{printf "%f", $0}')


# Report times
echo ""
echo -e "${bc}Execution times:${ebc}"
echo -e "${c}- Load time : ${loadtime}${ebc}"
echo -e "${c}- Index time: ${indextime}${ebc}"
echo -e "${c}- Plan time : ${plantime}${ebc}"
