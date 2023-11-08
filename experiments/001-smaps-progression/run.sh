function run_experiment {
    local docker_image_name=$1
    local docker_container_name=$2

    docker run \
        --name ${docker_container_name} \
        ${docker_image_name} 001-smaps-progression.experiment \
    | watch_memory
}
