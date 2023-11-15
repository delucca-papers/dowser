def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.signal import HistogramEqualization
    from common.cluster import run_attribute

    quality = HistogramEqualization()

    return run_attribute(quality, input, n_workers, single_threaded)
