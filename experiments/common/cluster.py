def build_pipeline(n_workers: int = 1):
    from dasf.pipeline import Pipeline
    from dasf.pipeline.executors import DaskPipelineExecutor

    dask = DaskPipelineExecutor(local=True, cluster_kwargs={"n_workers": n_workers})
    pipeline = Pipeline("Pipeline", executor=dask)

    return pipeline
