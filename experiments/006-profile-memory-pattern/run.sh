#!/usr/bin/env bash

SSH_KEY_LOCATION=$1
SSH_KEY=$(cat $SSH_KEY_LOCATION)
IMAGE_TAG="dowser/006-profile-memory-pattern"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
NUM_SHAPES=20
#NUM_SHAPES=50
NUM_SAMPLES=1
#NUM_SAMPLES=35
SHAPE_BASE_SIZE=200
PRESSURE_PRECISION=0.05
WITH_MEMORY_PRESSURE_SUFFIX="with-memory-pressure"
WITHOUT_MEMORY_PRESSURE_SUFFIX="without-memory-pressure"
ATTRIBUTE="envelope"
RESULTS_DIR="$(pwd)/results"

echo "Building Docker images"
docker build --build-arg SSH_KEY="$SSH_KEY" --target experiment -t ${IMAGE_TAG}-experiment .
docker build --build-arg SSH_KEY="$SSH_KEY" --target evaluate -t ${IMAGE_TAG}-evaluate .

echo "---"

echo "Profiling memory usage without memory pressure"
for (( s=1; s<=$NUM_SHAPES; s++ )); do
  shape="$(($SHAPE_BASE_SIZE*$s))"
  echo "Running experiment for shape $shape"
  for (( i=1; i<=$NUM_SAMPLES; i++ )); do
    echo "    Varying D3"
    docker run --rm \
      -v $RESULTS_DIR:/data \
      ${IMAGE_TAG}-experiment \
      --experiment-id $TIMESTAMP \
      --attribute $ATTRIBUTE \
      --output-suffix $WITHOUT_MEMORY_PRESSURE_SUFFIX \
      --d3 $shape
  done
done

echo "---"

echo "Profiling memory usage with memory pressure"
skip_headers=1
while IFS=, read -r d1 d2 d3 varying_d1 varying_d2 varying_d3 initial_memory_usage_kb input_data_memory_usage_kb final_memory_usage_kb memory_pressure elapsed_time
do
    if ((skip_headers))
    then
        ((skip_headers--))
    else
      shape=$d3
      shape_memory_limit=$final_memory_usage_kb
      echo "Running experiment for shape $shape"

      last_experiment_exit_code=0
      current_memory_pressure=0

      while [ "$last_experiment_exit_code" -eq 0 ]; do
        iteration_memory_difference=$(echo $current_memory_pressure $shape_memory_limit | awk '{printf "%4.3f\n",$1*$2}')
        iteration_memory_limit=$(echo $shape_memory_limit $iteration_memory_difference | awk '{printf "%.0f\n",$1 - $2}')
        echo "---"
        echo "  Current shape: $shape"
        echo "  Current memory pressure: $current_memory_pressure"
        echo "  Shape base memory limit: $shape_memory_limit KB"
        echo "  Experiment memory limit: $iteration_memory_limit KB"

        docker run --rm \
          -m ${iteration_memory_limit}k \
          -v $RESULTS_DIR:/data \
          ${IMAGE_TAG}-experiment \
          --experiment-id $TIMESTAMP \
          --attribute $ATTRIBUTE \
          --output-suffix $WITH_MEMORY_PRESSURE_SUFFIX \
          --d3 $shape \
          --pressure $current_memory_pressure

        last_experiment_exit_code=$?
        echo "  Experiment finished with exit code $last_experiment_exit_code"

        if [ "$last_experiment_exit_code" -eq 0 ]; then
          current_memory_pressure=$(echo $current_memory_pressure $PRESSURE_PRECISION | awk '{printf "%4.3f\n",$1+$2}')
        else
          echo "  Experiment failed with exit code $last_experiment_exit_code"
          echo "  Memory pressure limit: $current_memory_pressure"
        fi
      done
    fi
done < "$(pwd)/results/$TIMESTAMP/iterations-$WITHOUT_MEMORY_PRESSURE_SUFFIX.csv"

echo "---"

echo "Evaluting and parsing results"
docker run --rm \
  -v $RESULTS_DIR:/data \
  ${IMAGE_TAG}-evaluate \
  --experiment-id $TIMESTAMP