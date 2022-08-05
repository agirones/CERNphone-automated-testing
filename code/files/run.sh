#!/bin/bash
# Main user controlled variables
# Report type to provide
REPORT_TYPE='table_full'
# voip_patrol log level on console
VP_LOG_LEVEL=0

# Private variables
declare -a CONTAINERS=('database' 'prepare' 'vp' 'report' )
export REGISTRY='gitlab-registry.cern.ch/cernphone/functional-testing/'

# Images names
for CONTAINER in ${CONTAINERS[@]}; do
    export ${CONTAINER^^}_IMAGE_NAME=$REGISTRY$CONTAINER
done

# Containers names
for CONTAINER in ${CONTAINERS[@]}; do
    export ${CONTAINER^^}_CONTAINER_NAME=$CONTAINER
done

CURRENT_DIRECTORY=`pwd`

# Volumes paths in host
PATH_HOST_INPUT=$CURRENT_DIRECTORY/tmp/input
PATH_HOST_OUTPUT=$CURRENT_DIRECTORY/tmp/output
PATH_HOST_VOICE_FILES=$CURRENT_DIRECTORY/voice_ref_files
PATH_HOST_SCENARIOS=$CURRENT_DIRECTORY/scenarios

# Volumes in containers
PATH_PREPARE_INPUT=/opt/input
PATH_PREPARE_OUTPUT=/opt/output
PATH_VP_OUTPUT=/output
PATH_VP_VOICE_FILES=/voice_ref_files
PATH_REPORT_INPUT=/opt/scenarios
PATH_REPORT_OUTPUT=/opt/report

# voip_patrol
VP_PORT=5060
VP_RESULT_FILE="result.jsonl"
VP_LOG_LEVEL_FILE=${VP_LOG_LEVEL}

pull_images() {
    for CONTAINER in ${CONTAINERS[@]}; do
        REPOSITORY=${CONTAINER^^}_IMAGE_NAME
        docker pull ${!REPOSITORY}
    done
}

run_voip_patrol() {
    PATH_HOST_VP_CONFIGURATION=$CURRENT_DIRECTORY/tmp/input/${CURRENT_SCENARIO}/voip_patrol.xml
    PATH_VP_CONFIGURATION=/xml/${CURRENT_SCENARIO}.xml

    if [ ! -f $PATH_VP_CONFIGURATION ]; then
        return
    fi

    docker run --name=${VP_CONTAINER_NAME} \
    --env XML_CONF=`echo ${CURRENT_SCENARIO}` \
    --env PORT=`echo ${VP_PORT}` \
    --env RESULT_FILE=`echo ${VP_RESULT_FILE}` \
    --env LOG_LEVEL=`echo ${VP_LOG_LEVEL}` \
    --env LOG_LEVEL_FILE=`echo ${VP_LOG_LEVEL_FILE}` \
    --volume $PATH_HOST_VP_CONFIGURATION:$PATH_VP_CONFIGURATION \
    --volume $PATH_HOST_OUTPUT:$PATH_VP_OUTPUT \
    --volume $PATH_HOST_VOICE_FILES:$PATH_VP_VOICE_FILES \
    --network none \
    --rm \
    ${VP_IMAGE_NAME}

}

run_prepare() {
    docker rm ${PREPARE_CONTAINER_NAME} >> /dev/null 2>&1

    docker run --name=${PREPARE_CONTAINER_NAME} \
        --env SCENARIO_NAME=`echo ${SCENARIO}` \
        --volume $PATH_HOST_SCENARIOS:$PATH_PREPARE_INPUT \
        --volume $PATH_HOST_INPUT:$PATH_PREPARE_OUTPUT \
        --network none \
        --rm \
        ${PREPARE_IMAGE_NAME}

}

run_report() {
    docker rm ${REPORT_CONTAINER_NAME} >> /dev/null 2>&1

    docker run --name=${REPORT_CONTAINER_NAME} \
        --env REPORT_FILE=`echo ${VP_RESULT_FILE}` \
        --env REPORT_TYPE=`echo ${REPORT_TYPE}` \
        --volume $PATH_HOST_INPUT:$PATH_REPORT_INPUT \
        --volume $PATH_HOST_OUTPUT:$PATH_REPORT_OUTPUT \
        --network host \
        --rm \
        ${REPORT_IMAGE_NAME}

}

run_database() {
    PATH_HOST_DB_CONFIGURATION=${CURRENT_DIRECTORY}/tmp/input/${CURRENT_SCENARIO}/database.xml
    PATH_DB_CONFIGURATION=/xml/${CURRENT_SCENARIO}.xml

    docker rm ${DATABASE_CONTAINER_NAME} >> /dev/null 2>&1

    if [ ! -f $PATH_HOST_DB_CONFIGURATION ]; then 
        return
    fi

    docker run --name=${DATABASE_CONTAINER_NAME} \
        --env SCENARIO=`echo ${CURRENT_SCENARIO}` \
        --env STAGE=`echo $1` \
        --volume $PATH_HOST_DB_CONFIGURATION:$PATH_DB_CONFIGURATION \
        --network host \
        --rm \
        ${DATABASE_IMAGE_NAME}

}

# Script controlled variables
# First arument - single test to run
SCENARIO="$1"
if [ "x${SCENARIO}" != "x" ]; then
    SCENARIO=`basename ${SCENARIO} | cut -f 1 -d .`
fi

pull_images

rm -f tmp/input/scenarios.done
run_prepare

if [ ! -f ${CURRENT_DIRECTORY}/tmp/input/scenarios.done ]; then
    echo "Scenarios are not prepared, please check for the errors"
    exit 1
fi


rm -f ${CURRENT_DIRECTORY}/tmp/output/${VP_RESULT_FILE}

if [ -z ${SCENARIO} ]; then
    for DIRECTORY in ${CURRENT_DIRECTORY}/tmp/input/*; do
        if [ -f ${DIRECTORY}/voip_patrol.xml ]; then
            CURRENT_SCENARIO=`basename ${DIRECTORY}`
            run_database pre
            run_voip_patrol
            run_database post
        fi
    done
else
    CURRENT_SCENARIO=${SCENARIO}
    run_database pre
    run_voip_patrol
    run_database post
fi

run_report
