def run(input, n_workers=1, single_threaded=False):
    from dasf_seismic.attributes.dip_azm import GradientStructureTensor3DDip
    from common.cluster import run_attribute

    quality = GradientStructureTensor3DDip()

    return run_attribute(quality, input, n_workers, single_threaded)
