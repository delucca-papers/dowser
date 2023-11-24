#!/usr/bin/env bash

source "${BASE_DIR}/common/scripts/reports.sh"

function handle_stdout {
    local is_verbose=$1
    
    local setup_already_reported=false

    while read execution_id execution_entrypoint_pid line; do
        if [[ ${is_verbose} = true ]]; then
            if [[ ${setup_already_reported} = false ]]; then
                echo "Execution ID: ${execution_id}"
                echo "Execution entrypoint PID: ${execution_entrypoint_pid}"

                setup_already_reported=true
            fi

            echo ${line}
        fi
    done
}

function observe_memory_usage_signals {
    local output_dir=$1

    local output_filepath="${output_dir}/memory-usage.csv"
    local execution_id
    local initial_mem_usage
    local data_mem_usage
    local computing_mem_usage
    local final_mem_usage
    local mem_usage_log
    
    if [[ ! -f "${output_filepath}" ]]; then
        echo "Execution ID, Initial memory usage, Data memory usage, Computing memory usage, Final memory usage" > "${output_filepath}"
    fi
    
    while read piped_execution_id piped_execution_entrypoint_pid line; do
        if [[ -z ${execution_id} ]]; then
            execution_id=${piped_execution_id}
        fi

        if [[ ${line} == *"MEM_USAGE"* ]]; then
            read -r current_rss_mem_usage current_shared_clean_mem_usage current_shared_dirty_mem_usage current_swap_mem_usage <<< $(report_process_memory_usage ${piped_execution_entrypoint_pid})
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
    
    echo "${execution_id}, ${initial_mem_usage}, ${data_mem_usage}, ${computing_mem_usage}, ${final_mem_usage}" >> "${output_filepath}"
}

function observe_execution_time_signal {
    local output_dir=$1
    
    local stored_file
    local filepath="${output_dir}/execution-time.csv"
    
    while read execution_id execution_entrypoint_pid line; do
        if [[ ${line} == *"EXECUTION_TIME"* ]]; then
            if [[ -z ${stored_file} ]]; then
                if [[ ! -f "${filepath}" ]]; then
                    echo "Execution ID, Execution time" > "${filepath}"
                fi
                
                stored_file=true
            fi

            local execution_time=$(echo ${line} | cut -d ' ' -f 3)
            echo "${execution_id}, ${execution_time}" >> "${filepath}"
        fi
       
        echo ${execution_id} ${execution_entrypoint_pid} ${line}
    done
}

function observe_stdout {
    local container_name=$1
    local experiment_name=$2
    local output_dir=$3
    
    local execution_id
    local execution_entrypoint_pid
    local pid_reference_file_stored
    
    while read line; do
        if [[ -z ${execution_id} ]]; then
            execution_id=$(uuidgen)
        fi

        if [[ -z ${execution_entrypoint_pid} ]]; then
            execution_entrypoint_pid=$(docker top ${container_name} | grep ${experiment_name} | tail -n 1 | tr -s '[:space:]' | cut -d ' ' -f 2)
        fi
        
        if [[ -z ${pid_reference_file_stored} ]]; then
            __store_pid_reference ${output_dir} ${execution_id} ${execution_entrypoint_pid}
            pid_reference_file_stored=true
        fi
             
        echo ${execution_id} ${execution_entrypoint_pid} ${line}
    done
}

function __store_pid_reference {
    local output_dir=$1
    local execution_id=$2
    local execution_entrypoint_pid=$3
    
    local reference_filepath="${output_dir}/entrypoint-pid-reference.csv"

    if [[ ! -f ${reference_filepath} ]]; then
        echo "Execution ID, Execution entrypoint PID" > ${reference_filepath}
    fi

    echo "${execution_id}, ${execution_entrypoint_pid}" >> ${reference_filepath}
}

function __summarize_mem_usage {
    local rss_usage=$1
    local shared_clean_usage=$2
    local shared_dirty_usage=$3
    local swap_usage=$4
    
    local total_mem_usage=$((${rss_usage} + ${shared_clean_usage} + ${shared_dirty_usage} + ${swap_usage}))

    echo ${total_mem_usage}
}