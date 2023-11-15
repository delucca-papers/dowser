def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.texture import GLCMASM
    from common.cluster import run_attribute

    quality = GLCMASM()

    return run_attribute(quality, input, n_workers, single_threaded)
