def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.noise_reduction import Convolution
    from common.cluster import run_attribute

    quality = Convolution()

    return run_attribute(quality, input, n_workers, single_threaded)
