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

    __extract_min_max_memory_usage(df)
    __extract_time_elapsed(df)


def __extract_min_max_memory_usage(df):
    shapes = df["dimension_z"].unique()
    memory_used_per_z = df.groupby(["dimension_z"])["memory_used"].apply(list)

    max_memory_used = []
    min_memory_used = []
    for result in memory_used_per_z:
        max_memory_used.append(max(result))
        min_memory_used.append(min(result))

    plt.plot(shapes, max_memory_used, label="Max memory used", marker="o")
    plt.plot(shapes, min_memory_used, label="Min memory used", marker="o")
    plt.xlabel("Input shape")
    plt.ylabel("Memory usage (KB)")
    plt.legend()
    plt.savefig(f"{args.dirpath}/min-max-memory-usage.png")
    plt.clf()


def __extract_time_elapsed(df):
    time_elapsed_per_z = df.groupby(["dimension_z"])["elapsed_time"].apply(list)
    memory_pressure_per_z = df.groupby(["dimension_z"])["memory_pressure"].apply(list)
    shapes = df["dimension_z"].unique()

    fig, ax1 = plt.subplots()
    color = "tab:red"
    ax1.set_xlabel("Memory pressure (%)")
    ax1.set_ylabel("Time elapsed (s) - (first 3)", color=color)
    ax1.tick_params(axis="y", labelcolor=color)

    for i, time_elapsed in enumerate(time_elapsed_per_z[:3]):
        memory_pressure = [
            pressure * 100 for pressure in memory_pressure_per_z.iloc[:3].iloc[i]
        ]

        ax1.plot(
            memory_pressure,
            time_elapsed,
            label=f"Shape {shapes[i]}",
            marker="o",
            color=color,
        )

    color = "tab:blue"
    ax2 = ax1.twinx()
    ax2.set_ylabel("Time elapsed (s) - (last 3)", color=color)
    ax2.tick_params(axis="y", labelcolor=color)

    for i, time_elapsed in enumerate(time_elapsed_per_z[-3:]):
        memory_pressure = [
            pressure * 100 for pressure in memory_pressure_per_z.iloc[-3:].iloc[i]
        ]

        ax2.plot(
            memory_pressure,
            time_elapsed,
            label=f"Shape {shapes[i]}",
            marker="o",
            color=color,
        )

    fig.tight_layout()
    plt.savefig(f"{args.dirpath}/time-elapsed.png")
    plt.clf()


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
