function run_experiment {
    echo "Starting smaps progression experiment"

    local docker_image_name=$1
    local docker_container_name=$2

    docker run \
        --name ${docker_container_name} \
        ${docker_image_name} 001-smaps-progression.experiment \
    | setup_observer | observe_memory_usage | handle_log
}

function print_experiment_summary {
    :
}