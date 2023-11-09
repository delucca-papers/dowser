from sys import argv


def run(d1: int, d2: int, d3: int, n_workers: int):
    from common import data, report, constants

    report.wait_for_signal(constants.CAPTURE_INITIAL_MEMORY_USAGE)

    input = data.generate(d1, d2, d3)
    report.wait_for_signal(constants.CAPTURE_DATA_MEMORY_USAGE)

    from common.cluster import build_pipeline
    from common.attributes import envelope

    pipeline = build_pipeline(n_workers)
    envelope.run(input, pipeline)
    report.wait_for_signal(constants.CAPTURE_COMPUTING_MEMORY_USAGE)


if __name__ == "__main__":
    d1 = int(argv[1])
    d2 = int(argv[2])
    d3 = int(argv[3])
    num_workers = int(argv[4])

    run(d1, d2, d3, num_workers)
