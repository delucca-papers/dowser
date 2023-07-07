import argparse
import os

from code import run_hilbert_transform


def run(args):
    print("Started experiment")

    elapsed_time, memory_usage_kb = run_hilbert_transform(args)

    print("Finished experiment")
    print("Time taken: {} seconds".format(elapsed_time))
    print("Memory used: {} KB".format(memory_usage_kb))

    variant_shape = args.d3
    result_filepath = os.path.join(
        os.path.dirname(__file__), args.dirpath, "results.log"
    )
    with open(result_filepath, "a+") as f:
        f.write(
            "{},{},{},{}\n".format(
                variant_shape, args.pressure, memory_usage_kb, elapsed_time
            )
        )


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
        "--pressure", help="Percentage of memory pressure", type=str, default=0
    )
    parser.add_argument(
        "--dirpath",
        help="The dirpath to store the experiment result",
        type=str,
        default="/data",
    )
    args = parser.parse_args()

    run(args)
