OUTPUT_DIR="001-smaps-progression/output/${OUTPUT_TIMESTAMP}"
OUTPUT_SMAPS_HISTORY_FILENAME="smaps-history.csv"

D1=1000
D2=1000
D3=100
NUM_WORKERS=3

function run_experiment {
    echo "Starting smaps progression experiment"
    
    __collect_results
    __evaluate_results
}

function print_experiment_summary {
    local amount_smap_logs=$(cat "${OUTPUT_DIR}/${OUTPUT_SMAPS_HISTORY_FILENAME}" | tail -n +2 | wc -l)

    printf "${TABLE_FORMAT}" "Shape of dimension 1" "${D1}"
    printf "${TABLE_FORMAT}" "Shape of dimension 2" "${D2}"
    printf "${TABLE_FORMAT}" "Shape of dimension 3" "${D3}"
    printf "${TABLE_FORMAT}" "Number of workers" "${NUM_WORKERS}"
    printf "${TABLE_FORMAT}" "Collected smaps data points" "${amount_smap_logs}"
}

function __collect_results {
    echo "Collecting smaps data..."
    launch_container 001-smaps-progression.experiment \
        ${D1} \
        ${D2} \
        ${D3} \
        ${NUM_WORKERS} \
    | setup_observer | observe_memory_usage_signals | __setup_memory_usage_wacher | handle_log
    
    echo "Finished collecting smaps data"
}

function __evaluate_results {
    echo ${TERMINAL_DIVIDER}
    echo "Evaluating results..."
    launch_container 001-smaps-progression.evaluate
    
    echo "Results evaluated"
}


function __setup_memory_usage_wacher {
    local launched_watcher
    
    while read execution_id execution_entrypoint_pid line; do
        if [[ -z ${launched_watcher} ]]; then
            __watch_memory_usage ${execution_entrypoint_pid} &
            launched_watcher=true
        fi

        echo $execution_id $execution_entrypoint_pid $line
    done
}

function __watch_memory_usage {
    local execution_entrypoint_pid=$1
    local interval=0.1
    local history_filepath="${OUTPUT_DIR}/${OUTPUT_SMAPS_HISTORY_FILENAME}"
    
    echo "Execution entrypoint PID, Timestamp, PID, Process type, Rss, Shared_Clean, Shared_Dirty, Swap" > ${history_filepath}

    while ps -p ${execution_entrypoint_pid} > /dev/null; do
        local children_pids=$(ps -o pid --no-headers --ppid ${execution_entrypoint_pid})

        timestamp=$(get_timestamp)
        read -r rss shared_clean shared_dirty swap <<< $(capture_process_memory_usage ${execution_entrypoint_pid})
        if [[ ! -z ${rss} ]]; then
            echo "${execution_entrypoint_pid}, ${timestamp}, ${execution_entrypoint_pid}, "client", ${rss}, ${shared_clean}, ${shared_dirty}, ${swap}" >> ${history_filepath}
        fi
        
        for child_pid in ${children_pids}; do
            read -r child_rss child_shared_clean child_shared_dirty child_swap <<< $(capture_process_memory_usage ${child_pid})
            if [[ ! -z ${child_rss} ]]; then
                echo "${execution_entrypoint_pid}, ${timestamp}, ${child_pid}, "server", ${child_rss}, ${child_shared_clean}, ${child_shared_dirty}, ${child_swap}" >> ${history_filepath}
            fi
        done

        snapshot_number=$((snapshot_number + 1))
        sleep ${interval}
    done
}