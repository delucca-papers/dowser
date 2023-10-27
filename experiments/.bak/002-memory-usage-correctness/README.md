# Memory Usage Correctness

The idea of this experiment is to check the correctness of the memory usage reports we get on experiment [001-hilbert-transform](../001-hilbert-transform).
The experiment itself runs a Docker container in two scenarios:
- One with a few more megabytes of RAM available than the expected consumption (collected by the previous experiment);
- One with a few less megabytes of RAM available.

The goal for this experiment is to show that the expected memory usage is correct.

## Replicating the experiment

To replicate this experiment please follow these steps:

### Step 1: Install prerequisites

- Docker

### Step 2: Run the experiment

```sh
chmod +x ./run.sh
run.sh
```

### Step 3: Evaluate the results

During the execution you should see a few logs.
You should see both a log explaining that the container crashed (as expected) with low RAM and that it works with the expected amount of RAM.
