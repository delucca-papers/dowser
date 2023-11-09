def run():
    from common import data, report, constants

    report.wait_for_signal(constants.CAPTURE_INITIAL_MEMORY_USAGE)

    input = data.generate(1000, 1000, 1000)
    report.wait_for_signal(constants.CAPTURE_DATA_MEMORY_USAGE)

    from common.cluster import build_pipeline
    from common.attributes import envelope

    pipeline = build_pipeline()
    envelope.run(input, pipeline)
    report.wait_for_signal(constants.CAPTURE_COMPUTING_MEMORY_USAGE)


if __name__ == "__main__":
    run()
