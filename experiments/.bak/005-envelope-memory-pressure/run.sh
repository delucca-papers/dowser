#!/usr/bin/env bash

IMAGE_TAG='dowser/005-envelope-memory-pressure'
NUM_SHAPES=50
SHAPE_BASE_SIZE=200
PRESSURE_PRECISION=0.05
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RESULTS_DIR="results/$TIMESTAMP"
SSH_KEY_LOCATION=$1
SSH_KEY=$(cat $SSH_KEY_LOCATION)

echo "Starting experiment $TIMESTAMP"
echo "Results will be stored on $RESULTS_DIR"
echo

docker build --build-arg SSH_KEY="$SSH_KEY" --target profile -t ${IMAGE_TAG}-profile .
docker build --build-arg SSH_KEY="$SSH_KEY" --target experiment -t ${IMAGE_TAG}-experiment .
docker build --build-arg SSH_KEY="$SSH_KEY" --target evaluate -t ${IMAGE_TAG}-evaluate .
mkdir -p $RESULTS_DIR

# ---

echo "Profiling memory usage"

for (( s=1; s<=$NUM_SHAPES; s++ )); do
  shape="$(($SHAPE_BASE_SIZE*$s))"
  echo "Profiling memory usage for shape $shape"

  docker run --rm \
    -v ./$RESULTS_DIR:/data \
    ${IMAGE_TAG}-profile \
    --d3 $shape

  echo
done

SHAPE_MEMORY_LIMIT=($(cat $RESULTS_DIR/memory_usage.log))

# ---

echo "Starting experiments"

for (( s=1; s<=$NUM_SHAPES; s++ )); do
  shape="$(($SHAPE_BASE_SIZE*$s))"
  shape_memory_limit=${SHAPE_MEMORY_LIMIT[$s-1]}
  echo "---"
  echo "---"
  echo "---"
  echo "Running experiment for shape $shape"

  last_experiment_exit_code=0
  current_memory_pressure=0

  while [ "$last_experiment_exit_code" -eq 0 ]; do
    iteration_memory_difference=$(echo $current_memory_pressure $shape_memory_limit | awk '{printf "%4.3f\n",$1*$2}')
    iteration_memory_limit=$(echo $shape_memory_limit $iteration_memory_difference | awk '{printf "%.0f\n",$1 - $2}')
    echo "---"
    echo "  Current memory pressure: $current_memory_pressure"
    echo "  Shape base memory limit: $shape_memory_limit KB"
    echo "  Experiment memory limit: $iteration_memory_limit KB"

    docker run --rm \
      -m ${iteration_memory_limit}k \
      -v ./$RESULTS_DIR:/data \
      ${IMAGE_TAG}-experiment \
      --d3 $shape \
      --pressure $current_memory_pressure

    last_experiment_exit_code=$?
    echo "  Experiment finished with exit code $last_experiment_exit_code"

    if [ "$last_experiment_exit_code" -eq 0 ]; then
      current_memory_pressure=$(echo $current_memory_pressure $PRESSURE_PRECISION | awk '{printf "%4.3f\n",$1+$2}')
    else
      echo "  Experiment failed with exit code $last_experiment_exit_code"
      echo "  Current memory pressure: $current_memory_pressure"
    fi
  done
done

# ---

echo
echo "Evaluating results"

docker run --rm \
  -v ./$RESULTS_DIR:/data \
  ${IMAGE_TAG}-evaluate
