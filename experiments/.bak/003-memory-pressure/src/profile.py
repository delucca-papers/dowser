import argparse
import os

from code import run_hilbert_transform


def run(args):
    _, memory_usage_kb = run_hilbert_transform(args)

    print("Finished profiling")
    print("Memory used: {} KB".format(memory_usage_kb))

    memory_usage_filepath = os.path.join(
        os.path.dirname(__file__), args.dirpath, "memory_usage.log"
    )
    with open(memory_usage_filepath, "a+") as f:
        f.write("{}\n".format(memory_usage_kb))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--d1", help="Amount of records on the first dimension", type=int, default=100
    )
    parser.add_argument(
        "--d2", help="Amount of records on the second dimension", type=int, default=100
    )
    parser.add_argument(
        "--d3", help="Amount of records on the third dimension", type=int, default=100
    )
    parser.add_argument(
        "--dirpath",
        help="The dirpath to store the profiled memory usage",
        type=str,
        default="/data",
    )
    args = parser.parse_args()

    run(args)
