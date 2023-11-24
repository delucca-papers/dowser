#!/usr/bin/env bash

OUTPUT_DIR="002-memory-usage-profile/output/${OUTPUT_TIMESTAMP}"
OUTPUT_EXECUTION_INPUT_PARAMETERS_REFERENCE_FILENAME="execution-input-parameters-reference.csv"

D2=100
D3=100
NUM_SAMPLES=35
SHAPE_BASE_SIZE=200
SHAPE_STEP_SIZE=200
SHAPE_LIMIT_SIZE=10000

source "${BASE_DIR}/common/scripts/launchers.sh"
source "${BASE_DIR}/common/scripts/observers.sh"
source "${BASE_DIR}/common/scripts/reports.sh"

function run_experiment {
    echo "Starting memory usage profile experiment"
    
    __collect_results
    __evaluate_results
}

function print_experiment_summary {
    printf "${TABLE_FORMAT}" "Dimension 1 shape base size" "${SHAPE_BASE_SIZE}"
    printf "${TABLE_FORMAT}" "Dimension 1 shape step size" "${SHAPE_STEP_SIZE}"
    printf "${TABLE_FORMAT}" "Shape of dimension 2" "${D2}"
    printf "${TABLE_FORMAT}" "Shape of dimension 3" "${D3}"
    printf "${TABLE_FORMAT}" "Number of samples" "${NUM_SAMPLES}"
    printf "${TABLE_FORMAT}" "Shape limit size" "${SHAPE_LIMIT_SIZE}"
}

function __collect_results {
    local attributes=$(ls "${BASE_DIR}/common/attributes" | sed s"/.py//g")
    attributes="envelope semblance"
    local shapes=$(for i in `seq ${SHAPE_BASE_SIZE} ${SHAPE_STEP_SIZE} ${SHAPE_LIMIT_SIZE}`; do echo $i; done)
    local iterations_total=$(($(echo ${shapes} | wc -w) * ${NUM_SAMPLES} * $(echo ${attributes} | wc -w)))
    local current_iteration=1
    
    for attribute in ${attributes}; do
        for shape in ${shapes}; do
            for i in `seq 1 ${NUM_SAMPLES}`; do
                report_progress ${current_iteration} ${iterations_total} "computing attribute ${attribute} using shape (${shape}, ${D2}, ${D3})"
                __collect_sample_results ${attribute} ${shape} ${i}

                current_iteration=$((${current_iteration} + 1))
            done
        done
    done
    
    echo "Finished collecting data"
}

function __collect_sample_results {
    local attribute=$1
    local shape=$2
    local iteration_number=$3

    launch_container 002-memory-usage-profile.experiment \
        ${shape} \
        ${D2} \
        ${D3} \
        ${attribute} \
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
                    echo "Execution ID, Attribute name, Shape D1, Shape D2, Shape D3" > "${reference_filepath}"
                fi
                
                read -r attribute_name d1 d2 d3 <<< $(__parse_input_parameters "${line}")
                echo "${execution_id}, ${attribute_name}, ${d1}, ${d2}, ${d3}" >> "${reference_filepath}"

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

    echo ${attribute_name} ${d1} ${d2} ${d3}
}

function __evaluate_results {
    echo ${TERMINAL_DIVIDER}
    echo "Evaluating results..."
    launch_container 002-memory-usage-profile.evaluate
    
    echo "Results evaluated"
}
