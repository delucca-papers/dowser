#!/usr/bin/env bash

OUTPUT_DIR="003-memory-pressure-profile/output/${OUTPUT_TIMESTAMP}"
OUTPUT_EXECUTION_INPUT_PARAMETERS_REFERENCE_FILENAME="execution-input-parameters-reference.csv"
OUTPUT_MEMORY_PRESSURE_FILENAME="memory-pressure.csv"

D2=100
D3=100
PRESSURE_START_PERCENTAGE=5
PRESSURE_PERCENTAGE_STEP=5
SUMMARY_RELATIVE_FILEPATH="003-memory-pressure-profile/assets/memory-usage-summary.csv"

source "${BASE_DIR}/common/scripts/launchers.sh"
source "${BASE_DIR}/common/scripts/observers.sh"
source "${BASE_DIR}/common/scripts/reports.sh"

function run_experiment {
    echo "Starting memory pressure profile experiment"
    
    __collect_results
    __evaluate_results
}

function print_experiment_summary {
    printf "${TABLE_FORMAT}" "Shape of dimension 2" "${D2}"
    printf "${TABLE_FORMAT}" "Shape of dimension 3" "${D3}"
    printf "${TABLE_FORMAT}" "Pressure start percentage" "${PRESSURE_START_PERCENTAGE}%"
    printf "${TABLE_FORMAT}" "Pressure percentage step" "${PRESSURE_PERCENTAGE_STEP}%"
    printf "${TABLE_FORMAT}" "Summary file" "${SUMMARY_RELATIVE_FILEPATH}"
}

function __collect_results {
    local data=$(cat "${BASE_DIR}/${SUMMARY_RELATIVE_FILEPATH}" | tail -n +2)
    local iterations_total=$(echo ${data} | wc -w)
    local current_iteration=1
    local last_execution_exit_code=0
    
    for line in ${data}; do
        local attribute_name=$(echo ${line} | cut -d ',' -f 1)
        local shape=$(echo ${line} | cut -d ',' -f 2)
        local max_memory_usage=$(echo ${line} | cut -d ',' -f 6 | cut -d '.' -f 1)
        local current_memory_pressure=${PRESSURE_START_PERCENTAGE}
        

        while [ "${last_execution_exit_code}" -eq "0" ]; do
            local memory_restriction=$((${max_memory_usage} * $((100 - ${current_memory_pressure})) / 100))

            report_progress ${current_iteration} ${iterations_total} "computing attribute ${attribute_name} using shape (${shape}, ${D2}, ${D3}) with memory pressure of ${current_memory_pressure}%"
            __collect_sample_results ${memory_restriction} ${current_memory_pressure} ${attribute_name} ${shape} ${current_iteration}

            current_memory_pressure=$((${current_memory_pressure} + ${PRESSURE_PERCENTAGE_STEP}))
            last_execution_exit_code=$(cat "${OUTPUT_DIR}/${OUTPUT_MEMORY_PRESSURE_FILENAME}" | tail -n 1 | cut -d ',' -f 3)
        done
        
        current_memory_pressure=${PRESSURE_START_PERCENTAGE}
        last_execution_exit_code=0
        current_iteration=$((${current_iteration} + 1))
    done
    
    echo "Finished collecting data"
}

function __collect_sample_results {
    local memory_restriction=$1
    local memory_pressure=$2
    local attribute=$3
    local shape=$4
    local iteration_number=$5

    launch_container_with_memory_restriction \
        ${memory_restriction} \
        003-memory-pressure-profile.experiment \
        ${shape} \
        ${D2} \
        ${D3} \
        ${attribute} \
    | observe_stdout "${DOCKER_CONTAINER_NAME}" "${EXPERIMENT_NAME}" "${OUTPUT_DIR}" \
    | __observe_input_parameters \
    | __observe_memory_pressure ${memory_pressure} \
    | observe_execution_time_signal "${OUTPUT_DIR}" \
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

function __observe_memory_pressure {
    local current_memory_pressure=$1

    local stored_file
    local filepath="${OUTPUT_DIR}/${OUTPUT_MEMORY_PRESSURE_FILENAME}"
    
    while read execution_id execution_entrypoint_pid line; do
        if [[ ${line} == *"EXIT_CODE"* ]]; then
            if [[ -z ${stored_file} ]]; then
                if [[ ! -f "${filepath}" ]]; then
                    echo "Execution ID, Memory pressure, Exit code" > "${filepath}"
                fi
                
                stored_file=true
            fi

            local exit_code=$(echo ${line} | cut -d ' ' -f 3)
            echo "${execution_id}, ${current_memory_pressure}, ${exit_code}" >> "${filepath}"
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
    launch_container 003-memory-pressure-profile.evaluate
    
    echo "Results evaluated"
}
