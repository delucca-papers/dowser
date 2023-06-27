# Hilbert Transform Experiment

This experiment aims to explore the memory usage relationship with the input shape size.
The general idea is to execute the Hilbert Transform (implemented on SciPy) with a tensor while varying each dimension.
At the end of the experiment we should see a graph showing a behavior like the following:

TODO: ADD GRAPH

As you can see, while varying the dimension the memory usage varies linerly.

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

After the execution is finished, a new timestamped folder will be created on your results folder, containing the graph and the logs from the experiment.
