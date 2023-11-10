OUTPUT_DIR="002-memory-usage-profile/output/${OUTPUT_TIMESTAMP}"

D1=500
D2=500
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
        "semblance" \
    | setup_observer | observe_memory_usage_signals | handle_log
    
    echo "Finished collecting smaps data"
}

function __evaluate_results {
    echo ${TERMINAL_DIVIDER}
    echo "Evaluating results..."
    launch_container 002-memory-usage-profile.evaluate
    
    echo "Results evaluated"
}