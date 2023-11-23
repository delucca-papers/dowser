from sys import argv
from importlib import import_module


def run(
    d1: int,
    d2: int,
    d3: int,
    attribute_name: str,
    dataset_name: str,
    dataset_type: str,
    chunk_size: int,
):
    from common import data, report, constants

    report.wait_for_signal(constants.CAPTURE_INITIAL_MEMORY_USAGE)

    if dataset_type == "synthetic":
        input = data.generate(d1, d2, d3)
        input = input[0:chunk_size]
    else:
        input = data.load(dataset_name, chunk_size)
    report.wait_for_signal(constants.CAPTURE_DATA_MEMORY_USAGE)

    attribute = import_module(f"common.attributes.{attribute_name}")
    attribute.run(input, single_threaded=True)
    report.wait_for_signal(constants.CAPTURE_COMPUTING_MEMORY_USAGE)


if __name__ == "__main__":
    d1 = int(argv[1])
    d2 = int(argv[2])
    d3 = int(argv[3])
    attribute_name = str(argv[4])
    dataset_name = str(argv[5])
    dataset_type = str(argv[6])
    chunk_size = int(argv[7])

    print(
        f"Capture INPUT_PARAMETERS {d1} {d2} {d3} {attribute_name} {dataset_name} {dataset_type} {chunk_size}"
    )

    run(d1, d2, d3, attribute_name, dataset_name, dataset_type, chunk_size)
