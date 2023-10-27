import argparse
import resource
import time
import dask
import envelope


def run(args):
    start_time = time.time()

    dask.config.set(scheduler="single-threaded")

    input = build_data(args)
    envelope.run(input)

    # Gather final metrics
    elapsed_time = time.time() - start_time
    memory_usage_kb = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss

    # Store the results
    import os

    result_filepath = os.path.join(
        os.path.dirname(__file__), args.dirpath, "results.log"
    )
    with open(result_filepath, "a+") as f:
        f.write(
            "{},{},{},{},{},{}\n".format(
                args.d1,
                args.d2,
                args.d3,
                args.pressure,
                memory_usage_kb,
                elapsed_time,
            )
        )


def build_data(args):
    import dask.array as da
    import numpy as np

    shape = (args.d1, args.d2, args.d3)
    x = np.random.random(shape)
    return da.array(x)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
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
        "--pressure", help="Percentage of memory pressure", type=str, default=0
    )
    parser.add_argument(
        "--dirpath",
        help="The dirpath to store the experiment result",
        type=str,
        default="/data",
    )
    args = parser.parse_args()

    run(args)
