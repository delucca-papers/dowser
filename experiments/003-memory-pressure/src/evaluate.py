import argparse
import os
import pandas as pd


def run(args):
    results_filepath = os.path.join(args.dirpath, "results.log")
    df = pd.read_csv(
        results_filepath,
        header=None,
        names=["shape", "memory_pressure", "memory_used", "elapsed_time"],
    )
    print(df)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dirpath",
        help="The dirpath containing the stored results",
        type=str,
        default="/data",
    )
    args = parser.parse_args()

    run(args)
