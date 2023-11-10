from sys import argv
from importlib import import_module


def run(d1: int, d2: int, d3: int, n_workers: int, attribute_name: str):
    from common import data, report, constants

    report.wait_for_signal(constants.CAPTURE_INITIAL_MEMORY_USAGE)

    input = data.generate(d1, d2, d3)
    report.wait_for_signal(constants.CAPTURE_DATA_MEMORY_USAGE)

    from common.cluster import build_pipeline

    attribute = import_module(f"common.attributes.{attribute_name}")

    pipeline = build_pipeline(n_workers)
    attribute.run(input, pipeline)
    report.wait_for_signal(constants.CAPTURE_COMPUTING_MEMORY_USAGE)


if __name__ == "__main__":
    d1 = int(argv[1])
    d2 = int(argv[2])
    d3 = int(argv[3])
    num_workers = int(argv[4])
    attribute_name = str(argv[5])

    run(d1, d2, d3, num_workers, attribute_name)
