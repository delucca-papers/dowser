# Experiments

This folder contains all experiments related to Dowser.
Each experiment is in a folder with a numeric prefix, like: `001-experiment-name`.
The prefix is used to sort the experiments in the order they were performed.

Each experiment folder contains a `README.md` file with the description of the experiment.
Besides the experiments folders, you may find other folders that may contain shared code or data.

## Running an experiment

To run an experiment you can open a new shell on this folder and run the following command:

```sh
./run.sh -s <ssh-key-path> -e <experiment-folder-name>
```

> **Important:**
> You **must** provide both the `-s` parameter, as well as the `-e` parameter.
> Also, you must grant access to the SSH key you're using to your Github account in order to install the private dependencies.

## Experiments

- [**001-smaps-progression**](./001-smaps-progression/README.md): Evaluates the progression of the `smaps_rollup` file while running a seismic attribute with DASF;
- [**002-memory-usage-profile**](./002-memory-usage-profile/): Evaluates the memory usage profile of all seismic attributes;
- [**003-memory-pressure-profile**](./003-memory-pressure-profile/): Evaluates how much memory pressure each seismic attribute accepts;
- [**004-synthetic-data-validation**](./004-synthetic-data-validation/): Validates if synthetic data has the same memory usage profile as real data.
