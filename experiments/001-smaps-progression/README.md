# Smaps Progression Experiment

This experiment aims to understand the progression of the `smaps_rollup` file while running a seismic attribute with DASF.
The idea behind this experiment is to properly evaluate how is the progression of the `Rss`, `Shared`, and `Swap` memory.

## Experiment output files

This experiment output the following files:

- `entrypoint-pid-reference.csv`: This file contains the reference `PID` of the entrypoint process;
- `memory-usage.csv`: This file contains the memory usage of the different stages of the application (initializing, generating data, and computing);
- `smaps-history.csv`: This file contains the values of the mapped smaps keys while the application is running.
  To capture this, we have an observer process that runs every 0.1 seconds and captures the values of the smaps keys of the entrypoint process and its children.

## Conclusion

Based on the results of the experiment, it is clear that the RSS memory is the one that grows the most during the execution of the application.
Both shared and swap memory aren't relevant and doesn't grow much during the execution of the application.
The RSS memory of the worker process is pretty stable.
Also, most of the RSS memory is stored on the entrypoint process.

Based on this, we assume that since the workers are forked processes from the entrypoint, probably Linux is using a copy-write approach to share memory from the entrypoint (that contains the data) and the workers.
