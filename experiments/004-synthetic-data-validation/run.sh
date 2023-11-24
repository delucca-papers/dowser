#!/usr/bin/env bash

OUTPUT_DIR="004-synthetic-data-validation/output/${OUTPUT_TIMESTAMP}"
OUTPUT_EXECUTION_INPUT_PARAMETERS_REFERENCE_FILENAME="execution-input-parameters-reference.csv"

NUM_SAMPLES=1
CHUNK_SIZE=650
#NUM_SAMPLES=35
DATASETS="parihaka"
#DATASETS="f3 parihaka"

F3_SHAPE="650,950,461"
PARIHAKA_SHAPE="650,950,461"

source "${BASE_DIR}/common/scripts/launchers.sh"
source "${BASE_DIR}/common/scripts/observers.sh"
source "${BASE_DIR}/common/scripts/reports.sh"

function run_experiment {
    echo "Starting synthetic data validation experiment"
    
    __collect_results
    #__evaluate_results
}

function print_experiment_summary {
    printf "${TABLE_FORMAT}" "Number of samples" "${NUM_SAMPLES}"
    printf "${TABLE_FORMAT}" "Datasets" "${DATASETS}"
    printf "${TABLE_FORMAT}" "Chunk size" "${CHUNK_SIZE}"
}

function __collect_results {
    local attributes=$(ls "${BASE_DIR}/common/attributes" | sed s"/.py//g")
    attributes="envelope"
    local iterations_total=$(($(echo ${DATASETS} | wc -w) * ${NUM_SAMPLES} * $(echo ${attributes} | wc -w)))
    local current_iteration=1
    
    for attribute in ${attributes}; do
        for dataset in ${DATASETS}; do
            report_progress ${current_iteration} ${iterations_total} "comparing synthetic data for attribute ${attribute} using dataset ${dataset}"
            
            local dataset_shape=$(set -o posix; set | grep "${dataset^^}_SHAPE" | cut -d '=' -f 2)
            __collect_sample_results ${attribute} ${dataset_shape} ${dataset}

            current_iteration=$((${current_iteration} + 1))
        done
    done
    
    echo "Finished collecting data"
}

function __collect_sample_results {
    local attribute=$1
    local shape=$2
    local dataset=$3
    
    local d1=$(echo ${shape} | cut -d ',' -f 1)
    local d2=$(echo ${shape} | cut -d ',' -f 2)
    local d3=$(echo ${shape} | cut -d ',' -f 3)

    launch_container 004-synthetic-data-validation.experiment \
        ${d1} \
        ${d2} \
        ${d3} \
        ${attribute} \
        ${dataset} \
        "real" \
        ${CHUNK_SIZE} \
    | observe_stdout "${DOCKER_CONTAINER_NAME}" "${EXPERIMENT_NAME}" "${OUTPUT_DIR}" \
    | __observe_input_parameters \
    | observe_memory_usage_signals "${OUTPUT_DIR}" \
    | handle_stdout "${LOG_VERBOSE}"


    launch_container 004-synthetic-data-validation.experiment \
        ${d1} \
        ${d2} \
        ${d3} \
        ${attribute} \
        ${dataset} \
        "synthetic" \
        ${CHUNK_SIZE} \
    | observe_stdout "${DOCKER_CONTAINER_NAME}" "${EXPERIMENT_NAME}" "${OUTPUT_DIR}" \
    | __observe_input_parameters \
    | observe_memory_usage_signals "${OUTPUT_DIR}" \
    | handle_stdout "${LOG_VERBOSE}"
}

function __observe_input_parameters {
    local stored_reference
    local reference_filepath="${OUTPUT_DIR}/${OUTPUT_EXECUTION_INPUT_PARAMETERS_REFERENCE_FILENAME}"
    
    while read execution_id execution_entrypoint_pid line; do
        if [[ ${line} == *"INPUT_PARAMETERS"* ]]; then
            if [[ -z ${stored_reference} ]]; then
                if [[ ! -f "${reference_filepath}" ]]; then
                    echo "Execution ID, Attribute name, Shape D1, Shape D2, Shape D3, Dataset name, Dataset type, Chunk size" > "${reference_filepath}"
                fi
                
                read -r attribute_name d1 d2 d3 dataset_name dataset_type chunk_size <<< $(__parse_input_parameters "${line}")
                echo "${execution_id}, ${attribute_name}, ${d1}, ${d2}, ${d3}, ${dataset_name}, ${dataset_type}, ${chunk_size}" >> "${reference_filepath}"

                stored_reference=true
            fi
        fi
       
        echo ${execution_id} ${execution_entrypoint_pid} ${line}
    done
}

function __parse_input_parameters {
    local parameters=$1

    local d1=$(echo ${parameters} | cut -d ' ' -f 3)
    local d2=$(echo ${parameters} | cut -d ' ' -f 4)
    local d3=$(echo ${parameters} | cut -d ' ' -f 5)
    local attribute_name=$(echo ${parameters} | cut -d ' ' -f 6)
    local dataset_name=$(echo ${parameters} | cut -d ' ' -f 7)
    local dataset_type=$(echo ${parameters} | cut -d ' ' -f 8)
    local chunk_size=$(echo ${parameters} | cut -d ' ' -f 9)

    echo ${attribute_name} ${d1} ${d2} ${d3} ${dataset_name} ${dataset_type} ${chunk_size}
}

function __evaluate_results {
    echo ${TERMINAL_DIVIDER}
    echo "Evaluating results..."
    launch_container 004-synthetic-data-validation.evaluate
    
    echo "Results evaluated"
}
