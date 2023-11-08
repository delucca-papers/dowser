#!/usr/bin/env bash

EXPERIMENT_NAME=
DOCKER_SSH_KEY_PATH=
DOCKER_UID=1000
DOCKER_GID=984
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUTPUT_DIR="output/${TIMESTAMP}"

TERMINAL_COLUMNS=$(tput cols)
TABLE_COLUMNS=83
if [[ ${TERMINAL_COLUMNS} -lt 83 ]]; then TABLE_COLUMNS=${TERMINAL_COLUMNS}; fi
TABLE_FORMAT="%-50s : %30s\n"
TABLE_ROW_DIVIDER=$(printf -- "-%.0s"  $(seq 1 ${TABLE_COLUMNS}))
TABLE_DIVIDER=$(printf "=%.0s"  $(seq 1 ${TABLE_COLUMNS}))
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
    local rss_mem_usage_log
    local shared_clean_mem_usage_log
    local shared_dirty_mem_usage_log
    local swap_mem_usage_log

    while read line; do
        if [[ -z ${experiment_root_pid} ]]; then
            experiment_root_pid=$(docker top ${DOCKER_CONTAINER_NAME} | grep ${EXPERIMENT_NAME} | tail -n 1 | tr -s '[:space:]' | cut -d ' ' -f 2)
            echo "Experiment root PID is: ${experiment_root_pid}"
        fi

        if [[ ${line} == *"MEM_USAGE"* ]]; then
            read -r current_rss_mem_usage current_shared_clean_mem_usage current_shared_dirty_mem_usage current_swap_mem_usage <<< $(__capture_memory_usage ${experiment_root_pid})
            read -r current_mem_usage current_shared_mem_usage <<< $(__summarize_mem_usage ${current_rss_mem_usage} ${current_shared_clean_mem_usage} ${current_shared_dirty_mem_usage} ${current_swap_mem_usage})
            
            rss_mem_usage_log="${rss_mem_usage_log} ${current_rss_mem_usage}"
            shared_clean_mem_usage_log="${shared_clean_mem_usage_log} ${current_shared_clean_mem_usage}"
            shared_dirty_mem_usage_log="${shared_dirty_mem_usage_log} ${current_shared_dirty_mem_usage}"
            swap_mem_usage_log="${swap_mem_usage_log} ${current_swap_mem_usage}"
            final_mem_usage=${current_mem_usage}
            
            if [[ ${line} == *"INITIAL"* ]]; then
                initial_mem_usage=${current_mem_usage}
            elif [[ ${line} == *"DATA"* ]]; then
                if [[ -z ${initial_mem_usage} ]]; then
                    data_mem_usage=${current_mem_usage}
                else
                    data_mem_usage=$((${current_mem_usage} - ${initial_mem_usage}))
                fi
            elif [[ ${line} == *"COMPUTING"* ]]; then
                if [[ -z ${data_mem_usage} ]]; then
                    if [[ -z ${initial_mem_usage} ]]; then
                        computing_mem_usage=${current_mem_usage}
                    else
                        computing_mem_usage=$((${current_mem_usage} - ${initial_mem_usage}))
                    fi
                else
                    computing_mem_usage=$((${current_mem_usage} - ${data_mem_usage}))
                fi
            fi
            
            kill -CONT ${experiment_root_pid}
        fi
    done
    
    echo "Memory watch results:"
    echo ${TABLE_DIVIDER}
    printf "${TABLE_FORMAT}" "Initial memory usage" "${initial_mem_usage} kB"
    printf "${TABLE_FORMAT}" "Data memory usage" "${data_mem_usage} kB"
    printf "${TABLE_FORMAT}" "Computing memory usage" "${computing_mem_usage} kB"
    echo ${TABLE_ROW_DIVIDER}
    printf "${TABLE_FORMAT}" "Final memory usage" "${final_mem_usage} kB"
    echo ${TABLE_DIVIDER}
}

function __capture_memory_usage {
    local pid=$1
    local pid_rollup=$(cat "/proc/${pid}/smaps_rollup")
    local rss_usage=$(echo "${pid_rollup}" | grep -i "Rss" | awk '{print $2}')
    local shared_clean_usage=$(echo "${pid_rollup}" | grep -i "Shared_Clean" | awk '{print $2}')
    local shared_dirty_usage=$(echo "${pid_rollup}" | grep -i "Shared_Dirty" | awk '{print $2}')
    local swap_usage=$(echo "${pid_rollup}" | grep -i "Swap" | awk '{print $2}')
    
    echo ${rss_usage} ${shared_clean_usage} ${shared_dirty_usage} ${swap_usage}
}

function __summarize_mem_usage {
    local rss_usage=$1
    local shared_clean_usage=$2
    local shared_dirty_usage=$3
    local swap_usage=$4
    
    local total_mem_usage=$((${rss_usage} + ${shared_clean_usage} + ${shared_dirty_usage} + ${swap_usage}))
    local shared_mem_usage=$((${shared_clean_usage} + ${shared_dirty_usage}))

    echo ${total_mem_usage} ${shared_mem_usage}
}

function __run_experiment {
    echo "Removing past experiment containers"
    docker rm -f ${DOCKER_CONTAINER_NAME} > /dev/null 2>&1

    echo "Running experiment using image: ${DOCKER_IMAGE_NAME}"
    echo "Container name: ${DOCKER_CONTAINER_NAME}"
    echo ${DIVIDER}

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

            -o) OUTPUT_DIR="$2"; shift 2;;
            --output-dir) OUTPUT_DIR="${1#*=}"; shift 1;;

            *) echo "unknown option: $1" >&2; __help ; exit 1;;
      esac
    done
}

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
    printf "${TABLE_FORMAT}" "Output directory" ${OUTPUT_DIR}
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
