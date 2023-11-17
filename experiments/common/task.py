from importlib import import_module


def run_attribute(
    d1: int,
    d2: int,
    d3: int,
    attribute_name: str,
    n_workers: int = 1,
    single_threaded: bool = False,
):
    from common import data, report, constants

    report.wait_for_signal(constants.CAPTURE_INITIAL_MEMORY_USAGE)

    input = data.generate(d1, d2, d3)
    report.wait_for_signal(constants.CAPTURE_DATA_MEMORY_USAGE)

    attribute = import_module(f"common.attributes.{attribute_name}")
    attribute.run(input, n_workers=n_workers, single_threaded=single_threaded)
    report.wait_for_signal(constants.CAPTURE_COMPUTING_MEMORY_USAGE)
