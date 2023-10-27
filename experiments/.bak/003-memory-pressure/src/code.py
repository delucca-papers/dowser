import time
import resource
import dask
import scipy
import dask.array as da
import numpy as np


def run_hilbert_transform(args):
    start_time = time.time()

    # Create the input data
    dask.config.set(scheduler="single-threaded")

    shape = (args.d1, args.d2, args.d3)
    x = np.random.random(shape)
    darray = da.array(x)

    # Run the computation
    analytical_trace = darray.map_blocks(scipy.signal.hilbert, dtype=darray.dtype)
    analytical_trace.compute()

    # Get the final memory usage and elapsed time
    elapsed_time = time.time() - start_time
    memory_usage_kb = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss

    return elapsed_time, memory_usage_kb
