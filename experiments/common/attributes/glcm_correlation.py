def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.texture import GLCMCorrelation
    from common.cluster import run_attribute

    quality = GLCMCorrelation()

    return run_attribute(quality, input, n_workers, single_threaded)
