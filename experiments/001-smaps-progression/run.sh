OUTPUT_SMAPS_HISTORY="${OUTPUT_DIR}/smaps-history.csv"

D1=1000
D2=1000
D3=1000
NUM_WORKERS=3

function run_experiment {
    echo "Starting smaps progression experiment"

    local docker_image_name=$1
    local docker_container_name=$2

    echo "Running and collecting smaps data..."
    docker run \
        --name ${docker_container_name} \
        ${docker_image_name} 001-smaps-progression.experiment \
            ${D1} \
            ${D2} \
            ${D3} \
            ${NUM_WORKERS} \
    | setup_observer | observe_memory_usage_signals | __setup_memory_usage_wacher | handle_log
}

function print_experiment_summary {
    local amount_smap_logs=$(cat ${OUTPUT_SMAPS_HISTORY} | tail -n +2 | wc -l)

    printf "${TABLE_FORMAT}" "Shape of dimension 1" "${D1}"
    printf "${TABLE_FORMAT}" "Shape of dimension 2" "${D2}"
    printf "${TABLE_FORMAT}" "Shape of dimension 3" "${D3}"
    printf "${TABLE_FORMAT}" "Number of workers" "${NUM_WORKERS}"
    printf "${TABLE_FORMAT}" "Collected smaps data points" "${amount_smap_logs}"
}

function __setup_memory_usage_wacher {
    local experiment_root_pid
    local launched_watcher
    
    while read piped_experiment_id piped_experiment_root_pid line; do
        if [[ -z ${launched_watcher} ]]; then
            experiment_root_pid=${piped_experiment_root_pid}
            
            __watch_memory_usage ${experiment_root_pid} &
            launched_watcher=true
        fi

        echo $piped_experiment_id $piped_experiment_root_pid $line
    done
}

function __watch_memory_usage {
    local experiment_root_pid=$1
    local interval=0.1
    
    echo "Experiment root PID, PID, Rss, Shared_Clean, Shared_Dirty, Swap" > ${OUTPUT_SMAPS_HISTORY}

    while ps -p ${experiment_root_pid} > /dev/null; do
        local children_pids=$(ps -o pid --no-headers --ppid ${experiment_root_pid})

        read -r rss shared_clean shared_dirty swap <<< $(capture_process_memory_usage ${experiment_root_pid})
        if [[ ! -z ${rss} ]]; then
            echo "${experiment_root_pid}, ${experiment_root_pid}, ${rss}, ${shared_clean}, ${shared_dirty}, ${swap}" >> ${OUTPUT_SMAPS_HISTORY}
        fi
        
        for child_pid in ${children_pids}; do
            read -r child_rss child_shared_clean child_shared_dirty child_swap <<< $(capture_process_memory_usage ${child_pid})
            if [[ ! -z ${child_rss} ]]; then
                echo "${experiment_root_pid}, ${child_pid}, ${child_rss}, ${child_shared_clean}, ${child_shared_dirty}, ${child_swap}" >> ${OUTPUT_SMAPS_HISTORY}
            fi
        done

        sleep ${interval}
    done
}