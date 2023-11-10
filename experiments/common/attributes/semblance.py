def run(input, pipeline):
    from dasf_seismic.attributes.edge_detection import Semblance

    quality = Semblance()
    pipeline.add(quality, X=lambda: input)
    pipeline.run()

    return pipeline.get_result_from(quality).compute()
