import argparse
import dask
import scipy
import dask.array as da
import numpy as np


def run(args):
    print("Started processing")

    # Create the input data
    dask.config.set(scheduler="single-threaded")

    shape = (args.d1, args.d2, args.d3)
    x = np.random.random(shape)
    darray = da.array(x)

    # Run the computation
    analytical_trace = darray.map_blocks(scipy.signal.hilbert, dtype=darray.dtype)
    analytical_trace.compute()

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
