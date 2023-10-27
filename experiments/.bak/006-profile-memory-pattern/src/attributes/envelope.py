import dask

from dasf_seismic.attributes.complex_trace import Envelope


def run(input):
    quality = Envelope()
    with dask.config.set(scheduler="single-threaded"):
        result = quality._lazy_transform_cpu(X=input)
        result.compute()
