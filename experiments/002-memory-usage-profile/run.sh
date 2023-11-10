OUTPUT_DIR="002-memory-usage-profile/output/${OUTPUT_TIMESTAMP}"
OUTPUT_EXECUTION_INPUT_PARAMETERS_REFERENCE_FILENAME="execution-input-parameters-reference.csv"

D1=100
D2=100
D3=100
NUM_WORKERS=3

function run_experiment {
    echo "Starting memory usage profile experiment"
    
    __collect_results
    # __evaluate_results
}

function print_experiment_summary {
    printf "${TABLE_FORMAT}" "Shape of dimension 1" "${D1}"
    printf "${TABLE_FORMAT}" "Shape of dimension 2" "${D2}"
    printf "${TABLE_FORMAT}" "Shape of dimension 3" "${D3}"
    printf "${TABLE_FORMAT}" "Number of workers" "${NUM_WORKERS}"
}

function __collect_results {
    echo "Collecting smaps data..."
    launch_container 002-memory-usage-profile.experiment \
        ${D1} \
        ${D2} \
        ${D3} \
        ${NUM_WORKERS} \
        "envelope" \
    | setup_observer | __setup_input_parameters_reference_file | observe_memory_usage_signals | handle_log
    
    echo "Finished collecting smaps data"
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

function __parse_input_parameters {
    local parameters=$1
    local attribute_name=$(echo ${parameters} | cut -d ' ' -f 7)
    local d1=$(echo ${parameters} | cut -d ' ' -f 3)
    local d2=$(echo ${parameters} | cut -d ' ' -f 4)
    local d3=$(echo ${parameters} | cut -d ' ' -f 5)

    echo ${attribute_name} ${d1} ${d2} ${d3}
}

function __evaluate_results {
    echo ${TERMINAL_DIVIDER}
    echo "Evaluating results..."
    launch_container 002-memory-usage-profile.evaluate
    
    echo "Results evaluated"
}