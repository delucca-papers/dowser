import dask
from dasf.pipeline.executors import DaskPipelineExecutor
from dasf.pipeline import Pipeline

from dasf_seismic.attributes.complex_trace import Envelope

def run(input):
    run_in_pipeline(input)
    #run_lazy(input)

def run_lazy(input):
    quality = Envelope()
    with dask.config.set(scheduler="single-threaded"):
        result = quality._lazy_transform_cpu(X=input)
        result.compute()


def run_in_pipeline(input):
    quality = Envelope()
    dask = DaskPipelineExecutor(local=True, cluster_kwargs={"n_workers": 1})
    pipeline = Pipeline("Test", executor=dask)
    pipeline.add(quality, X=lambda: input)
    pipeline.run()
