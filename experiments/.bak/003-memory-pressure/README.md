# Memory pressure

Based on the results of the [memory usage correctness experiment](../002-memory-usage-correctness) we discovered that we can execute an algorithm even if we set it to run with less memory than it uses.
The goal for this experiment is to evaluate the following:
- The impact of executing the algorithm with less memory (execution time penalty);
- The relationship between the pressure and that penalty per shape;
- The amount of pressure we can apply per shape.

## Replicating the experiment

To replicate this experiment please follow these steps:

### Step 1: Install prerequisites

- Docker

### Step 2: Run the experiment

```sh
chmod +x ./run.sh
run.sh
```
