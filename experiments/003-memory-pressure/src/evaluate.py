import argparse
import os
import pandas as pd
import matplotlib.pyplot as plt


def run(args):
    results_filepath = os.path.join(args.dirpath, "results.log")
    df = pd.read_csv(
        results_filepath,
        header=None,
        names=[
            "dimension_x",
            "dimension_y",
            "dimension_z",
            "memory_pressure",
            "memory_used",
            "elapsed_time",
        ],
    )

    max_memory_used = []
    min_memory_used = []
    shapes = df["dimension_z"].unique()
    memory_used_per_z = df.groupby(["dimension_z"])["memory_used"].apply(list)

    for result in memory_used_per_z:
        max_memory_used.append(max(result))
        min_memory_used.append(min(result))

    plt.plot(shapes, max_memory_used, label="Max memory used", marker="o")
    plt.plot(shapes, min_memory_used, label="Min memory used", marker="o")
    plt.xlabel("Input shape")
    plt.ylabel("Memory usage (KB)")
    plt.legend()
    plt.savefig(f"{args.dirpath}/result.png")


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
