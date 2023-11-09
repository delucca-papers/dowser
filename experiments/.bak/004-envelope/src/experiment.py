import argparse
import resource


def run(args):
    # Get initial memory usage (before running anything)
    initial_memory_usage_kb = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss

    # Create the input data
    import dask

    # dask.config.set(scheduler="single-threaded")
    dask.config.set(scheduler="synchronous")

    input = __get_data(args)
    # Store the input data memory usage
    input_data_memory_usage_kb = (
        resource.getrusage(resource.RUSAGE_SELF).ru_maxrss - initial_memory_usage_kb
    )

    # Compute
    import envelope

    envelope.run(input)

    # Store the final memory usage
    final_memory_usage_kb = (
        resource.getrusage(resource.RUSAGE_SELF).ru_maxrss - initial_memory_usage_kb
    )

    # Store the results
    import os
    import pandas as pd

    varying_d1 = args.d1 != args.d2 and args.d1 != args.d3
    varying_d2 = args.d2 != args.d1 and args.d2 != args.d3
    varying_d3 = args.d3 != args.d1 and args.d3 != args.d2

    result_folder = os.path.join(args.output_dir, args.execution_id)
    os.makedirs(result_folder, exist_ok=True)
    iterations_filepath = os.path.join(result_folder, "iterations.csv")
    current_iteration_df = pd.DataFrame(
        {
            "iteration": args.iteration_number,
            "d1": args.d1,
            "d2": args.d2,
            "d3": args.d3,
            "varying_d1": varying_d1,
            "varying_d2": varying_d2,
            "varying_d3": varying_d3,
            "initial_memory_usage_kb": initial_memory_usage_kb,
            "input_data_memory_usage_kb": input_data_memory_usage_kb,
            "final_memory_usage_kb": final_memory_usage_kb,
        },
        index=[0],
    )

    if os.path.exists(iterations_filepath):
        iterations_df = pd.read_csv(iterations_filepath)
        iterations_df = pd.concat([iterations_df, current_iteration_df])
    else:
        iterations_df = current_iteration_df

    iterations_df.to_csv(iterations_filepath, index=False)


def __get_data(args):
    import dask.array as da
    import numpy as np

    shape = (args.d1, args.d2, args.d3)
    x = np.random.random(shape)
    return da.array(x)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--experiment-id", help="ID of the experiment", type=str, required=True
    )
    parser.add_argument(
        "--iteration-number",
        help="Number of the current iteration",
        type=int,
        default=1,
    )
    parser.add_argument(
        "--d1", help="Amount of records on the first dimension", type=int, default=100
    )
    parser.add_argument(
        "--d2", help="Amount of records on the second dimension", type=int, default=100
    )
    parser.add_argument(
        "--d3", help="Amount of records on the third dimension", type=int, default=100
    )
    parser.add_argument(
        "--output-dir",
        help="Directory to store the results",
        type=str,
        default="/data",
    )
    args = parser.parse_args()

    run(args)
