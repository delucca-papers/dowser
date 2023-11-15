def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.dip_azm import GradientStructureTensor3DAzm
    from common.cluster import run_attribute

    quality = GradientStructureTensor3DAzm()

    return run_attribute(quality, input, n_workers, single_threaded)
