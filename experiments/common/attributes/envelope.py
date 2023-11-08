def run(input, pipeline):
    from dasf_seismic.attributes.complex_trace import Envelope

    quality = Envelope()
    pipeline.add(quality, X=lambda: input)
    pipeline.run()
