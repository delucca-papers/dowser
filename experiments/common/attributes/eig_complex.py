def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.edge_detection import EigComplex
    from common.cluster import run_attribute

    quality = EigComplex()

    return run_attribute(quality, input, n_workers, single_threaded)
