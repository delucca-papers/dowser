#!/usr/bin/env bash

SSH_KEY_LOCATION=$1
SSH_KEY=$(cat $SSH_KEY_LOCATION)

docker build --build-arg SSH_KEY="$SSH_KEY" --target experiment -t dowser/004-envelope-experiment .
docker build --build-arg SSH_KEY="$SSH_KEY" --target evaluate -t dowser/004-envelope-evaluate .

TIMESTAMP=$(date +%Y%m%d%H%M%S)
NUM_SHAPES=50
NUM_SAMPLES=35
SHAPE_BASE_SIZE=200


for (( s=1; s<=$NUM_SHAPES; s++ )); do
  shape="$(($SHAPE_BASE_SIZE*$s))"
  echo "Running experiment for shape $shape"
  for (( i=1; i<=$NUM_SAMPLES; i++ )); do
    echo "  Iteration $i"
    echo "    Varying D1"
    docker run --rm \
      -v $(pwd)/results:/data \
      dowser/004-envelope-experiment \
      --experiment-id $TIMESTAMP \
      --iteration-number $i \
      --d1 $shape

    echo "    Varying D2"
    docker run --rm \
      -v $(pwd)/results:/data \
      dowser/004-envelope-experiment \
      --experiment-id $TIMESTAMP \
      --iteration-number $i \
      --d2 $shape

    echo "    Varying D3"
    docker run --rm \
      -v $(pwd)/results:/data \
      dowser/004-envelope-experiment \
      --experiment-id $TIMESTAMP \
      --iteration-number $i \
      --d3 $shape
  done
done

docker run --rm \
  -v $(pwd)/results:/data \
  dowser/004-envelope-evaluate \
  --experiment-id $TIMESTAMP \
