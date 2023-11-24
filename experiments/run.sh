#!/usr/bin/env bash

EXPERIMENT_NAME=
BASE_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

OUTPUT_TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUTPUT_DIR="output/${OUTPUT_TIMESTAMP}"

TERMINAL_COLUMNS=$(tput cols)
TERMINAL_DIVIDER=$(printf -- "-%.0s"  $(seq 1 ${TERMINAL_COLUMNS}))

TABLE_COLUMNS=113;
TABLE_FORMAT="%-40s : %70s\n"
TABLE_ROW_DIVIDER=$(printf -- "-%.0s"  $(seq 1 ${TABLE_COLUMNS}))
TABLE_DIVIDER=$(printf "=%.0s"  $(seq 1 ${TABLE_COLUMNS}))

DOCKER_SSH_KEY_PATH=
DOCKER_UID=1000
DOCKER_GID=984
DOCKER_IMAGE_NAME="discovery/dowser-experiments"
DOCKER_CONTAINER_NAME="discovery-experiments"

LOG_VERBOSE=false

function __help {
    cat << EOF
Executes a Dowser experiment. Such experiments are designed to evaluate the memory usage patterns of seismic attributes.

usage: $0 [OPTIONS]
    -h, --help           Show this message
    -e, --experiment     Experiment name                                     (required)
    -s, --ssh-key-path   Path to the SSH key used to clone the repository    (required)
    -u, --docker-uid     UID of the user inside the container                (default: 1000)
    -g, --docker-gid     GID of the user inside the container                (default: 984)
    -o, --output-dir     Output directory to store results                   (default: output/<timestamp>)
    -v, --verbose        Verbose output                                      (default: False)
EOF
}

function run {
    __parse_arguments $@
    __validate_arguments
    __print_about
    __build_image

    __run_experiment

    __print_summary
}

function __run_experiment {
    run_experiment $DOCKER_IMAGE_NAME $DOCKER_CONTAINER_NAME

    echo "Finished running experiment"
}

function __build_image {
    echo "Building image: ${DOCKER_IMAGE_NAME}"
    echo ${TERMINAL_DIVIDER}
    
    local docker_ssh_key=$(cat ${DOCKER_SSH_KEY_PATH})

    docker build \
        --build-arg SSH_KEY="${docker_ssh_key}" \
        --build-arg UID=${DOCKER_UID} \
        --build-arg GID=${DOCKER_GID} \
        -t ${DOCKER_IMAGE_NAME} \
        .
    
    echo ${TERMINAL_DIVIDER}
}

function __validate_arguments {
    __validate_experiment_name
    __validate_docker_arguments
    __validate_output_arguments
}

function __validate_experiment_name {
    if [ -z ${EXPERIMENT_NAME} ]; then
        echo "Experiment name is required"
        exit 1
    fi

    if [ ! -d ${EXPERIMENT_NAME} ]; then
        echo "Experiment named ${EXPERIMENT_NAME} does not exist"
        exit 1
    fi
}

function __validate_docker_arguments {
    if [ -z ${DOCKER_SSH_KEY_PATH} ]; then
        echo "Docker SSH key path is required"
        exit 1
    fi

    if [ ! -f ${DOCKER_SSH_KEY_PATH} ]; then
        echo "Docker SSH key path ${DOCKER_SSH_KEY_PATH} does not exist"
        exit 1
    fi
    
    number_re='^[0-9]+$'
    if [ -z ${DOCKER_UID} ] || ! [[ ${DOCKER_UID} =~ ${number_re} ]]; then
        echo "Docker UID must be a number"
        exit 1
    fi
    
    if [ -z ${DOCKER_GID} ] || ! [[ ${DOCKER_GID} =~ ${number_re} ]]; then
        echo "Docker GID must be a number"
        exit 1
    fi
}

function __validate_output_arguments {
    if [ -z ${OUTPUT_DIR} ]; then
        echo "Output directory is required"
        exit 1
    fi
    
    if [ -d ${OUTPUT_DIR} ]; then
        echo "Output directory ${OUTPUT_DIR} already exists"
        exit 1
    fi

    mkdir -p ${OUTPUT_DIR}
}

function __print_about {
    echo
    echo ${TABLE_DIVIDER}
    printf "${TABLE_FORMAT}" "Experiment name"  ${EXPERIMENT_NAME}
    printf "${TABLE_FORMAT}" "Start time" "$(date '+%Y-%m-%d %H-%M-%S')"
    printf "${TABLE_FORMAT}" "Total RAM" "$(free -m | awk '{print $2"MB"}' | sed -n 2p)"
    printf "${TABLE_FORMAT}" "Available RAM" "$(free -m | awk '{print $4"MB"}' | sed -n 2p)"
    printf "${TABLE_FORMAT}" "Docker image name" ${DOCKER_IMAGE_NAME}
    printf "${TABLE_FORMAT}" "Docker UID" ${DOCKER_UID}
    printf "${TABLE_FORMAT}" "Docker GID" ${DOCKER_GID}
    printf "${TABLE_FORMAT}" "Docker SSH key path" ${DOCKER_SSH_KEY_PATH}
    printf "${TABLE_FORMAT}" "Output directory" ${OUTPUT_DIR}
    echo ${TABLE_DIVIDER}
    echo
}

function __print_summary {
    echo ${TERMINAL_DIVIDER}
    echo "Experiment summary"
    echo ${TABLE_DIVIDER}
    printf "${TABLE_FORMAT}" "Output directory" "${OUTPUT_DIR}"
    print_experiment_summary
    echo ${TABLE_DIVIDER}
}

function __parse_arguments {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h) __help; exit 0;;
            --help) __help; exit 0;;

            -e) EXPERIMENT_NAME="$2"; source ${EXPERIMENT_NAME}/run.sh; shift 2;;
            --experiment=*) EXPERIMENT_NAME="${1#*=}"; source ${EXPERIMENT_NAME}/run.sh; shift 1;;

            -s) DOCKER_SSH_KEY_PATH="$2"; shift 2;;
            --ssh-key-path) DOCKER_SSH_KEY_PATH="${1#*=}"; shift 1;;
            
            -u) DOCKER_UID="$2"; shift 2;;
            --docker-uid) DOCKER_UID="${1#*=}"; shift 1;;

            -g) DOCKER_GID="$2"; shift 2;;
            --docker-gid) DOCKER_GID="${1#*=}"; shift 1;;

            -o) OUTPUT_DIR="$2"; shift 2;;
            --output-dir) OUTPUT_DIR="${1#*=}"; shift 1;;

            -v) LOG_VERBOSE=true; shift 1;;
            --verbose) LOG_VERBOSE=true; shift 1;;

            *) echo "unknown option: $1" >&2; __help ; exit 1;;
      esac
    done
}

run $@