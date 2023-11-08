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
DOCKER_CONTAINER_NAME="discovery-experiment"

function run {
    __parse_arguments $@
    __validate_arguments
    __print_about
    __build_image

    __run_experiment
}

function watch_memory {
    local experiment_root_pid
    local initial_mem_usage
    local data_mem_usage
    local computing_mem_usage
    local final_mem_usage

    while read line; do
        if [[ -z ${experiment_root_pid} ]]; then
            experiment_root_pid=$(docker top ${DOCKER_CONTAINER_NAME} | grep ${EXPERIMENT_NAME} | tail -n 1 | tr -s '[:space:]' | cut -d ' ' -f 2)
            echo "Experiment root PID is: ${experiment_root_pid}"
        fi

        if [[ ${line} == *"MEM_USAGE"* ]]; then
            local current_mem_usage=$(__capture_memory_usage ${experiment_root_pid})
            echo $current_mem_usage
            # TODO: PAREI AQUI

            if [[ ${line} == *"INITIAL"* ]]; then
                initial_mem_usage=${current_mem_usage}
            elif [[ ${line} == *"DATA"* ]]; then
                data_mem_usage=${current_mem_usage}
            elif [[ ${line} == *"COMPUTING"* ]]; then
                computing_mem_usage=${current_mem_usage}
            fi
        fi
    done

    echo
    echo ${TABLE_DIVIDER}
    printf "${TABLE_FORMAT}" "Initial memory usage" "${initial_mem_usage}"
    printf "${TABLE_FORMAT}" "Data memory usage" "${data_mem_usage}"
    printf "${TABLE_FORMAT}" "Computing memory usage" "${computing_mem_usage}"
    echo ${TABLE_DIVIDER}
    echo
}

function __capture_memory_usage {
    local pid=$1
    echo $(cat "/proc/${pid}/smaps_rollup")
}

function __run_experiment {
    echo "Removing past experiment containers"
    docker rm -f ${DOCKER_CONTAINER_NAME} > /dev/null 2>&1

    echo "Running experiment using image: ${DOCKER_IMAGE_NAME}"
    echo "Container name: ${DOCKER_CONTAINER_NAME}"

    source ${EXPERIMENT_NAME}/run.sh
    run_experiment $DOCKER_IMAGE_NAME $DOCKER_CONTAINER_NAME
}

function __build_image {
    echo "Building image: ${DOCKER_IMAGE_NAME}"
    echo ${DIVIDER}
    
    local docker_ssh_key=$(cat ${DOCKER_SSH_KEY_PATH})

    docker build \
        --build-arg SSH_KEY="${docker_ssh_key}" \
        --build-arg UID=${DOCKER_UID} \
        --build-arg GID=${DOCKER_GID} \
        -t ${DOCKER_IMAGE_NAME} \
        .
    
    echo ${DIVIDER}
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
    printf "${TABLE_FORMAT}" "Docker image name" ${DOCKER_IMAGE_NAME}
    printf "${TABLE_FORMAT}" "Docker UID" ${DOCKER_UID}
    printf "${TABLE_FORMAT}" "Docker GID" ${DOCKER_GID}
    printf "${TABLE_FORMAT}" "Docker SSH key path" ${DOCKER_SSH_KEY_PATH}
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
