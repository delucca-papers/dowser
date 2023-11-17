OUTPUT_DIR="003-memory-pressure-profile/output/${OUTPUT_TIMESTAMP}"
OUTPUT_EXECUTION_INPUT_PARAMETERS_REFERENCE_FILENAME="execution-input-parameters-reference.csv"
OUTPUT_MEMORY_PRESSURE_FILENAME="memory-pressure.csv"

D2=100
D3=100
NUM_SAMPLES=1
#NUM_SAMPLES=35
SHAPE_BASE_SIZE=100
#SHAPE_BASE_SIZE=200
SHAPE_STEP_SIZE=100
#SHAPE_STEP_SIZE=200
SHAPE_LIMIT_SIZE=100
#SHAPE_LIMIT_SIZE=10000
PRESSURE_START_PERCENTAGE=5
PRESSURE_PERCENTAGE_STEP=5

function run_experiment {
    echo "Starting memory pressure profile experiment"
    
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
    printf "${TABLE_FORMAT}" "Pressure percentage step" "${PRESSURE_PERCENTAGE_STEP}%"
}

function __collect_results {
    local data=$(cat "${BASE_DIR}/003-memory-pressure-profile/assets/memory-usage-summary.csv" | tail -n +2)
    local iterations_total=$(echo ${data} | wc -w)
    local current_iteration=1
    local last_execution_exit_code=0
    
    for line in ${data}; do
        local attribute_name=$(echo ${line} | cut -d ',' -f 1)
        local shape=$(echo ${line} | cut -d ',' -f 2)
        local max_memory_usage=$(echo ${line} | cut -d ',' -f 6 | cut -d '.' -f 1)
        local current_memory_pressure=${PRESSURE_START_PERCENTAGE}
        
        progress_bar ${current_iteration} ${iterations_total} "computing attribute ${attribute_name} using shape (${shape}, ${D2}, ${D3})"

        while [ ${last_execution_exit_code} -eq 0 ]; do
            local memory_restriction=$((${max_memory_usage} * $((100 - ${current_memory_pressure})) / 100))

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
    | setup_observer | __setup_input_parameters_reference_file | __setup_memory_pressure_file ${memory_pressure} | observe_memory_usage_signals | handle_log
}

function __setup_input_parameters_reference_file {
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

function __setup_memory_pressure_file {
    local stored_file
    local filepath="${OUTPUT_DIR}/${OUTPUT_MEMORY_PRESSURE_FILENAME}"
    local current_memory_pressure=$1
    
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
