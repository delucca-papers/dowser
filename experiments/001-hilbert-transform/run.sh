#!/usr/bin/env bash

docker build --target experiment -t dowser/001-hilber-transform-experiment .
docker build --target evaluate -t dowser/001-hilber-transform-evaluate .

TIMESTAMP=$(date +%Y%m%d%H%M%S)
NUM_SAMPLES=35
declare -a SHAPES=(
  "200"
  "400"
  "600"
  "800"
  "1000"
  "1200"
  "1400"
  "1600"
  "1800"
  "2000"
  "2200"
  "2400"
  "2600"
  "2800"
  "3000"
)

for shape in "${SHAPES[@]}"; do
    echo "Running experiment for shape $shape"
  for (( i=1; i<=$NUM_SAMPLES; i++ )); do
    echo "  Iteration $i"
    echo "    Varying D1"
    docker run --rm \
      -v $(pwd)/results:/data \
      dowser/001-hilber-transform-experiment \
      --experiment-id $TIMESTAMP \
      --iteration-number $i \
      --d1 $shape

    echo "    Varying D2"
    docker run --rm \
      -v $(pwd)/results:/data \
      dowser/001-hilber-transform-experiment \
      --experiment-id $TIMESTAMP \
      --iteration-number $i \
      --d2 $shape

    echo "    Varying D3"
    docker run --rm \
      -v $(pwd)/results:/data \
      dowser/001-hilber-transform-experiment \
      --experiment-id $TIMESTAMP \
      --iteration-number $i \
      --d3 $shape
  done
done

docker run --rm \
  -v $(pwd)/results:/data \
  dowser/001-hilber-transform-evaluate \
  --experiment-id $TIMESTAMP \
