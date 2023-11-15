def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.complex_trace import InstantaneousPhase
    from common.cluster import run_attribute

    quality = InstantaneousPhase()

    return run_attribute(quality, input, n_workers, single_threaded)
