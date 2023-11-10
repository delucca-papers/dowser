def run_attribute(attribute, input, n_workers=1, single_threaded=False):
    return (
        __run_single_threaded(attribute, input)
        if single_threaded
        else __run_in_local_cluster(attribute, input, n_workers)
    )


def __run_single_threaded(attribute, input):
    task = attribute._lazy_transform_cpu(X=input)
    return task.compute()


def __run_in_local_cluster(attribute, input, n_workers):
    pipeline = __build_pipeline(n_workers=n_workers)
    pipeline.add(attribute, X=lambda: input)
    pipeline.run()

    return pipeline.get_result_from(attribute).compute()


def __build_pipeline(n_workers: int = 1):
    from dasf.pipeline import Pipeline
    from dasf.pipeline.executors import DaskPipelineExecutor

    dask = DaskPipelineExecutor(local=True, cluster_kwargs={"n_workers": n_workers})
    pipeline = Pipeline("Pipeline", executor=dask)

    return pipeline
