def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.edge_detection import Semblance
    from common.cluster import run_attribute

    quality = Semblance()

    return run_attribute(quality, input, n_workers, single_threaded)
