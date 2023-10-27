#!/usr/bin/env bash

EXPERIMENT_NAME=
DOCKER_SSH_KEY_PATH=
DOCKER_UID=1000
DOCKER_GID=1000

TERMINAL_COLUMNS=$(tput cols)
TABLE_FORMAT="%-50s : %30s\n"
TABLE_DIVIDER=$(printf "=%.0s"  $(seq 1 83))
DIVIDER=$(printf -- "-%.0s"  $(seq 1 ${TERMINAL_COLUMNS:-83}))
DOCKER_IMAGE_NAME="discovery/dowser-experiments"

function run {
    __parse_arguments $@
    __validate_arguments
    __print_about
    __build_image
}

function __build_image {
    echo "Building image: ${DOCKER_IMAGE_NAME}"
    echo ${DIVIDER}
    
    docker build \
        --build-arg SSH_KEY="${SSH_KEY}" \
        --build-arg UID=${DOCKER_UID} \
        --build-arg GID=${DOCKER_GID} \
        -t ${DOCKER_IMAGE_NAME} \
        .
}

function __validate_arguments {
    __validate_experiment_name
    __validate_docker_arguments
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

function __parse_arguments {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h) __help; exit 0;;
            --help) __help; exit 0;;

            -e) EXPERIMENT_NAME="$2"; shift 2;;
            --experiment=*) EXPERIMENT_NAME="${1#*=}"; shift 1;;

            -s) DOCKER_SSH_KEY_PATH="$2"; shift 2;;
            --ssh-key-path) DOCKER_SSH_KEY_PATH="${1#*=}"; shift 1;;
            
            -u) DOCKER_UID="$2"; shift 2;;
            --docker-uid) DOCKER_UID="${1#*=}"; shift 1;;

            -g) DOCKER_GID="$2"; shift 2;;
            --docker-gid) DOCKER_GID="${1#*=}"; shift 1;;

            *) echo "unknown option: $1" >&2; __help ; exit 1;;
      esac
    done
}

function __help {
    cat << EOF
Executes a Dowser experiment. Such experiments are designed to evaluate the memory usage patterns of seismic attributes.

usage: $0 [OPTIONS]
    -h, --help           Show this message
    -e, --experiment     Experiment name
    -s, --ssh-key-path   Path to the SSH key used to clone the repository
    -u, --docker-uid     UID of the user inside the container
    -g, --docker-gid     GID of the user inside the container
EOF
}

function __print_about {
    echo
    echo ${TABLE_DIVIDER}
    printf "${TABLE_FORMAT}" "Experiment name"  ${EXPERIMENT_NAME}
    printf "${TABLE_FORMAT}" "Start time" "$(__get_date)"
    printf "${TABLE_FORMAT}" "Total RAM" "$(__get_total_ram)"
    printf "${TABLE_FORMAT}" "Available RAM" "$(__get_free_ram)"
    echo ${TABLE_DIVIDER}
    echo
}

function __get_date {
    echo $(date '+%Y-%m-%d %H-%M-%S')
}

function __get_free_ram {
    free -m | awk '{print $4"MB"}' | sed -n 2p
}

function __get_total_ram {
    free -m | awk '{print $2"MB"}' | sed -n 2p
}

run $@