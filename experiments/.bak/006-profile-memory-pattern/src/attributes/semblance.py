import dask

from dasf_seismic.attributes.edge_detection import Semblance


def run(input):
    quality = Semblance()
    with dask.config.set(scheduler="single-threaded"):
        result = quality._lazy_transform_cpu(X=input)
        result.compute()
