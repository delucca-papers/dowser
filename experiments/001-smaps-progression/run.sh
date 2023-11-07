function run_experiment {
    local docker_image_name=$1

    docker run ${docker_image_name} 001-smaps-progression.experiment
}
