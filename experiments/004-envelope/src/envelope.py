from dasf_seismic.attributes.complex_trace import Envelope
from dasf.pipeline.executors import DaskPipelineExecutor
from dasf.pipeline import Pipeline


def run(input):
    quality = Envelope()
    dask = DaskPipelineExecutor(local=True)
    pipeline = Pipeline("Envelope Experiment", executor=dask)

    pipeline.add(quality, X=lambda: input)
    pipeline.run()
