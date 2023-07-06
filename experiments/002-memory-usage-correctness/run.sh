#!/usr/bin/env bash

IMAGE_TAG='dowser/002-memory-usage-correctness'
MEMORY_USAGE_THRESHOLD=100000

docker build -t $IMAGE_TAG .

function docker_run() {
  local d1=$1
  local d2=$2
  local d3=$3

  docker run --rm \
    $IMAGE_TAG \
    --d1 $d1 \
    --d2 $d2 \
    --d3 $d3 2>/dev/null
}

function run_experiment() {
  local d1=$1
  local d2=$2
  local d3=$3
  local mem_usage_in_kb=$4

  local should_work_ram=$(( $mem_usage_in_kb + $MEMORY_USAGE_THRESHOLD ))
  local should_not_work_ram=$(( $mem_usage_in_kb - $MEMORY_USAGE_THRESHOLD ))

  echo "    Running experiment with d1=$d1, d2=$d2, d3=$d3"
  echo "      Trying to execute with a RAM limit of: $should_work_ram KB (should work)"
  ulimit -v $should_work_ram
  docker_run $d1 $d2 $d3

  echo "      Trying to execute with a RAM limit of: $should_not_work_ram KB (should not work)"
  ulimit -v $should_not_work_ram
  docker_run $d1 $d2 $d3
  ulimit
}

echo "Starting experiments"
echo "  Running first variant"

run_experiment 100 100 3000 1278488

echo "  Running first variant"
run_experiment 100 100 2000 1036252

echo "  Running first variant"
run_experiment 100 100 1600 970184
