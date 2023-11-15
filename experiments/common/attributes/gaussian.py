def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.noise_reduction import Gaussian
    from common.cluster import run_attribute

    quality = Gaussian()

    return run_attribute(quality, input, n_workers, single_threaded)
