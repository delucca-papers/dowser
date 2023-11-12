#!/usr/bin/env bash

EXPERIMENT_NAME=
BASE_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

OUTPUT_TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUTPUT_DIR="output/${OUTPUT_TIMESTAMP}"
OUTPUT_MEMORY_USAGE_FILENAME="memory-usage.csv"
OUTPUT_ENTRYPOINT_PID_REFERENCE_FILENAME="entrypoint-pid-reference.csv"

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

function run {
    __parse_arguments $@
    __validate_arguments
    __print_about
    __build_image

    __run_experiment

    __print_summary
}

function progress_bar {
    local progress=$1
    local percentage_characters=$((${#progress} + 6))
    local available_space=$((${TERMINAL_COLUMNS} - ${percentage_characters}))
    local progress_space=$((${progress} * ${available_space} / 100))
    local empty_space=$((${available_space} - ${progress_space}))
    local progress_seq=$(seq 1 ${progress_space})
    local empty_seq=$(seq 1 ${empty_space})
    local progress_bar=$(printf "#%.0s"  ${progress_seq})
    local empty_bar=$(printf " %.0s"  ${empty_seq})
    
    echo -ne "[${progress_bar}${empty_bar}] (${progress}%)\r"
}

function launch_container {
    docker rm -f ${DOCKER_CONTAINER_NAME} > /dev/null 2>&1
    docker run \
        -v ${BASE_DIR}/${OUTPUT_DIR}:/output \
        --name ${DOCKER_CONTAINER_NAME} \
        ${DOCKER_IMAGE_NAME} \
            $@
}

function setup_observer {
    local execution_id
    local execution_entrypoint_pid
    local pid_reference_file_stored
    
    while read line; do
        if [[ -z ${execution_id} ]]; then
            execution_id=$(uuidgen)
        fi

        if [[ -z ${execution_entrypoint_pid} ]]; then
            execution_entrypoint_pid=$(docker top ${DOCKER_CONTAINER_NAME} | grep ${EXPERIMENT_NAME} | tail -n 1 | tr -s '[:space:]' | cut -d ' ' -f 2)
        fi
        
        if [[ -z ${pid_reference_file_stored} ]]; then
            __store_pid_reference ${execution_id} ${execution_entrypoint_pid}
            pid_reference_file_stored=true
        fi
             
        echo ${execution_id} ${execution_entrypoint_pid} ${line}
    done
}


function observe_memory_usage_signals {
    local execution_id
    local initial_mem_usage
    local data_mem_usage
    local computing_mem_usage
    local final_mem_usage
    local mem_usage_log
    
    if [[ ! -f "${OUTPUT_DIR}/${OUTPUT_MEMORY_USAGE_FILENAME}" ]]; then
        __setup_memory_usage_file
    fi
    
    while read piped_execution_id piped_execution_entrypoint_pid line; do
        if [[ -z ${execution_id} ]]; then
            execution_id=${piped_execution_id}
        fi

        if [[ ${line} == *"MEM_USAGE"* ]]; then
            read -r current_rss_mem_usage current_shared_clean_mem_usage current_shared_dirty_mem_usage current_swap_mem_usage <<< $(capture_process_tree_memory_usage ${piped_execution_entrypoint_pid})
            read -r current_mem_usage <<< $(__summarize_mem_usage ${current_rss_mem_usage} ${current_shared_clean_mem_usage} ${current_shared_dirty_mem_usage} ${current_swap_mem_usage})
            
            mem_usage_log="${mem_usage_log} ${current_mem_usage}"
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
            
            kill -CONT ${piped_execution_entrypoint_pid}
        fi
        
        echo ${piped_execution_id} ${piped_execution_entrypoint_pid} ${line}
    done
    
    echo "${execution_id}, ${initial_mem_usage}, ${data_mem_usage}, ${computing_mem_usage}, ${final_mem_usage}" >> "${OUTPUT_DIR}/${OUTPUT_MEMORY_USAGE_FILENAME}"
}

function handle_log {
    local setup_already_reported=false

    while read execution_id execution_entrypoint_pid line; do
        if [[ ${LOG_VERBOSE} = true ]]; then
            if [[ ${setup_already_reported} = false ]]; then
                echo "Execution ID: ${execution_id}"
                echo "Execution entrypoint PID: ${execution_entrypoint_pid}"

                setup_already_reported=true
            fi

            echo ${line}
        fi
    done
}

function capture_process_tree_memory_usage {
    local parent_pid=${1}
    local children_pids=$(ps -o pid --no-headers --ppid ${parent_pid})

    read -r rss shared_clean shared_dirty swap <<< $(capture_process_memory_usage ${parent_pid})
    # TODO - Como vamos somar os processos filhos?
    
    echo ${rss} ${shared_clean} ${shared_dirty} ${swap}
}

function capture_process_memory_usage {
    local pid=${1}
    local pid_rollup=$(cat "/proc/${pid}/smaps_rollup" 2>/dev/null)
    local rss_usage=$(echo "${pid_rollup}" | grep -i "Rss" | awk '{print $2}')
    local shared_clean_usage=$(echo "${pid_rollup}" | grep -i "Shared_Clean" | awk '{print $2}')
    local shared_dirty_usage=$(echo "${pid_rollup}" | grep -i "Shared_Dirty" | awk '{print $2}')
    local swap_usage=$(echo "${pid_rollup}" | grep -i "Swap:" | awk '{print $2}')
    
    echo ${rss_usage} ${shared_clean_usage} ${shared_dirty_usage} ${swap_usage}
}

function get_timestamp {
    echo $(date +%s)
}

function progress_bar {
    local progress=$1
    local percentage_characters=$((${#progress} + 7))
    local available_space=$((${TERMINAL_COLUMNS} - ${percentage_characters}))
    local progress_space=$((${progress} * ${available_space} / 100))
    local empty_space=$((${available_space} - ${progress_space}))
    local progress_seq=$(seq 1 ${progress_space})
    local empty_seq=$(seq 1 ${empty_space})
    local progress_bar=$(printf "#%.0s"  ${progress_seq})
    local empty_bar=$(printf " %.0s"  ${empty_seq})
    
    echo -ne "[${progress_bar}${empty_bar}] (${progress}%)\r"
}

function __summarize_mem_usage {
    local rss_usage=$1
    local shared_clean_usage=$2
    local shared_dirty_usage=$3
    local swap_usage=$4
    
    local total_mem_usage=$((${rss_usage} + ${shared_clean_usage} + ${shared_dirty_usage} + ${swap_usage}))

    echo ${total_mem_usage}
}

function __setup_memory_usage_file {
    echo "Execution ID, Initial memory usage, Data memory usage, Computing memory usage, Final memory usage" > "${OUTPUT_DIR}/${OUTPUT_MEMORY_USAGE_FILENAME}"
}

function __store_pid_reference {
    local reference_filepath="${OUTPUT_DIR}/${OUTPUT_ENTRYPOINT_PID_REFERENCE_FILENAME}"

    if [[ ! -f ${reference_filepath} ]]; then
        echo "Execution ID, Execution entrypoint PID" > ${reference_filepath}
    fi

    echo "${1}, ${2}" >> ${reference_filepath}
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

function __print_summary {
    echo ${TERMINAL_DIVIDER}
    echo "Experiment summary"
    echo ${TABLE_DIVIDER}
    printf "${TABLE_FORMAT}" "Output directory" "${OUTPUT_DIR}"
    print_experiment_summary
    echo ${TABLE_DIVIDER}
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