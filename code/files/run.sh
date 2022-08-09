#!/bin/bash
# Main user controlled variables
# Report type to provide
REPORT_TYPE='monit_report'
# voip_patrol log level on console
VP_LOG_LEVEL=0

# Private variables
declare -a CONTAINERS=('database' 'prepare' 'vp' 'report' )
export REGISTRY='gitlab-registry.cern.ch/agirones/functional-testing/'

# Images names
for CONTAINER in ${CONTAINERS[@]}; do
    export ${CONTAINER^^}_IMAGE_NAME=$REGISTRY$CONTAINER
done

# Containers names
for CONTAINER in ${CONTAINERS[@]}; do
    export ${CONTAINER^^}_CONTAINER_NAME=$CONTAINER
done

WORKING_DIRECTORY=/root

# Volumes paths in host
PATH_HOST_INPUT=$WORKING_DIRECTORY/tmp/input
PATH_HOST_OUTPUT=$WORKING_DIRECTORY/tmp/output
PATH_HOST_VOICE_FILES=$WORKING_DIRECTORY/voice_ref_files
PATH_HOST_SCENARIOS=$WORKING_DIRECTORY/scenarios

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
VP_PATH_RESULT_FILE=${WORKING_DIRECTORY}/tmp/output/${VP_RESULT_FILE}

LOCK_DIRECTORY=/tmp/run.lock
PREPARE_CHECK=/root/tmp/input/scenarios.done


pull_images() {
    for CONTAINER in ${CONTAINERS[@]}; do
        REPOSITORY=${CONTAINER^^}_IMAGE_NAME
        docker pull ${!REPOSITORY}
    done
}


run_prepare() {
    rm -f $PREPARE_CHECK

    docker rm ${PREPARE_CONTAINER_NAME} >> /dev/null 2>&1

    docker run --name=${PREPARE_CONTAINER_NAME} \
        --env SCENARIO_NAME=`echo ${SCENARIO}` \
        --volume $PATH_HOST_SCENARIOS:$PATH_PREPARE_INPUT \
        --volume $PATH_HOST_INPUT:$PATH_PREPARE_OUTPUT \
        --network none \
        --rm \
        ${PREPARE_IMAGE_NAME}

    if [ ! -f $PREPARE_CHECK ]; then
        echo "Scenarios are not prepared, please check for the errors"
        exit 1
    fi
}

run_database() {
    PATH_HOST_DB_CONFIGURATION=${WORKING_DIRECTORY}/tmp/input/${WORKING_SCENARIO}/database.xml
    PATH_DB_CONFIGURATION=/xml/${WORKING_SCENARIO}.xml

    docker rm ${DATABASE_CONTAINER_NAME} >> /dev/null 2>&1

    if [ ! -f $PATH_HOST_DB_CONFIGURATION ]; then 
        return
    fi

    docker run --name=${DATABASE_CONTAINER_NAME} \
        --env SCENARIO=`echo ${WORKING_SCENARIO}` \
        --env STAGE=`echo $1` \
        --volume $PATH_HOST_DB_CONFIGURATION:$PATH_DB_CONFIGURATION \
        --network host \
        --rm \
        ${DATABASE_IMAGE_NAME}

}
 
run_voip_patrol() {
    PATH_HOST_VP_CONFIGURATION=$WORKING_DIRECTORY/tmp/input/${WORKING_SCENARIO}/voip_patrol.xml
    PATH_VP_CONFIGURATION=/xml/${WORKING_SCENARIO}.xml

    if [ ! -f $PATH_HOST_VP_CONFIGURATION ]; then
        return
    fi

    docker run --name=${VP_CONTAINER_NAME} \
    --env XML_CONF=`echo ${WORKING_SCENARIO}` \
    --env PORT=`echo ${VP_PORT}` \
    --env RESULT_FILE=`echo ${VP_RESULT_FILE}` \
    --env LOG_LEVEL=`echo ${VP_LOG_LEVEL}` \
    --env LOG_LEVEL_FILE=`echo ${VP_LOG_LEVEL_FILE}` \
    --volume $PATH_HOST_VP_CONFIGURATION:$PATH_VP_CONFIGURATION \
    --volume $PATH_HOST_OUTPUT:$PATH_VP_OUTPUT \
    --volume $PATH_HOST_VOICE_FILES:$PATH_VP_VOICE_FILES \
    --network host \
    --rm \
    ${VP_IMAGE_NAME}

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

if ! mkdir "$LOCK_DIRECTORY"; then
  echo >&2 "cannot acquire lock, giving up on $LOCK_DIRECTORY"
  exit 1
fi

while getopts ":ipt:rh" opt; do
  case $opt in
    i)
      pull_images
      ;;
    p)
      run_prepare
      ;;
    t)
      rm -f $VP_PATH_RESULT_FILE

      WORKING_SCENARIO=`basename ${OPTARG} | cut -f 1 -d .`
      run_database pre
      run_voip_patrol
      run_database post
      ;;
    :)
      rm -f $VP_PATH_RESULT_FILE

      for DIRECTORY in ${WORKING_DIRECTORY}/tmp/input/*; do
        if [ -f ${DIRECTORY}/voip_patrol.xml ]; then
            WORKING_SCENARIO=`basename ${DIRECTORY}`
            run_database pre
            run_voip_patrol
            run_database post
        fi
      done
      ;;
    r)
      run_report
      ;;
    h)
        echo "Usage:  run.sh [OPTIONS] test_names"
        echo ""
        echo "Options:" >&2
        echo "      -i	pull all images from repository" >&2
        echo "      -p	runs prepare container" >&2
        echo "      -t	if a scenario_name provided, run that specific scenario. Otherwise, run all tests with database pre, vp, and database post" >&2
        echo "      -r	run report container" >&2
        echo "      -h	shows this help" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ $OPTIND -eq 1 ]; then
    pull_images
    run_prepare
    rm -f $VP_PATH_RESULT_FILE

    if [ "$#" -eq 0 ]; then 
        for DIRECTORY in ${WORKING_DIRECTORY}/tmp/input/*; do
          if [ -f ${DIRECTORY}/voip_patrol.xml ]; then
              WORKING_SCENARIO=`basename ${DIRECTORY}`
              run_database pre
              run_voip_patrol
              run_database post
          fi
      done
    else
        for SCENARIO in "$@"; do
            WORKING_SCENARIO=`basename ${SCENARIO} | cut -f 1 -d .`
            run_database pre
            run_voip_patrol
            run_database post
        done
    fi
    run_report
fi
rm -r /tmp/run.lock
