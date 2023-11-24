#!/usr/bin/env bash

function launch_container {
    docker rm -f ${DOCKER_CONTAINER_NAME} > /dev/null 2>&1
    docker run \
        -v ${BASE_DIR}/${OUTPUT_DIR}:/output \
        -v ${HOME}/.cache/dasf:/home/dowser/.cache/dasf \
        --name ${DOCKER_CONTAINER_NAME} \
        ${DOCKER_IMAGE_NAME} \
            $@
}

function launch_container_with_memory_restriction {
    local memory_limit=$1

    docker rm -f ${DOCKER_CONTAINER_NAME} > /dev/null 2>&1
    docker run \
        -m ${memory_limit}k \
        -v ${BASE_DIR}/${OUTPUT_DIR}:/output \
        -v ${HOME}/.cache/dasf:/home/dowser/.cache/dasf \
        --name ${DOCKER_CONTAINER_NAME} \
        ${DOCKER_IMAGE_NAME} \
            ${@:2} 2> /dev/null
    
    local exit_code=$?
    echo "Capture EXIT_CODE: ${exit_code}"
}

