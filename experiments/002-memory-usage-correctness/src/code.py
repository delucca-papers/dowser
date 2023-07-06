import argparse
import time
import resource
import gc
import dask
import scipy
import dask.array as da
import numpy as np


def run(args):
    print("Started processing")

    # Create the input data
    dask.config.set(scheduler="single-threaded")
    gc.collect()

    shape = (args.d1, args.d2, args.d3)
    gc.collect()
    x = np.random.random(shape)
    gc.collect()
    darray = da.array(x)
    gc.collect()

    # Run the computation
    analytical_trace = darray.map_blocks(scipy.signal.hilbert, dtype=darray.dtype)
    gc.collect()
    analytical_trace.compute()
    gc.collect()
    print(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss)

    print("Finished processing")


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
    args = parser.parse_args()

    run(args)
