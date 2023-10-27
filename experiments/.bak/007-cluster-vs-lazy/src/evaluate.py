import argparse
import pandas as pd
import matplotlib.pyplot as plt


def run(args):
    __extract_memory_profile_without_memory_pressure(args)
    __extract_memory_profile_with_memory_pressure(args)
    
def __extract_memory_profile_without_memory_pressure(args):
    experiment_dirpath = f"{args.output_dir}/{args.experiment_id}"
    df = pd.read_csv(f"{experiment_dirpath}/iterations-without-memory-pressure.csv")

    df_dim_1 = df[df["varying_d1"] == True]
    df_dim_2 = df[df["varying_d2"] == True]
    df_dim_3 = df[df["varying_d3"] == True]

    shapes_dim_1 = df_dim_1["d1"].unique()
    shapes_dim_2 = df_dim_2["d2"].unique()
    shapes_dim_3 = df_dim_3["d3"].unique()

    means_dim_1 = df_dim_1.groupby("d1")["final_memory_usage_kb"].mean()
    means_dim_2 = df_dim_2.groupby("d2")["final_memory_usage_kb"].mean()
    means_dim_3 = df_dim_3.groupby("d3")["final_memory_usage_kb"].mean()

    if len(means_dim_1) > 0:
        plt.plot(shapes_dim_1, means_dim_1, label="Varying Dimension 1", marker="o")
    
    if len(means_dim_2) > 0:
        plt.plot(shapes_dim_2, means_dim_2, label="Varying Dimension 2", marker="o")
        
    if len(means_dim_3) > 0:
        plt.plot(shapes_dim_3, means_dim_3, label="Varying Dimension 3", marker="o")

    plt.xlabel("Input shape")
    plt.ylabel("Max memory usage (KB)")
    plt.legend()
    plt.savefig(f"{experiment_dirpath}/memory-profile-without-memory-pressure.png")
    plt.clf()
    
def __extract_memory_profile_with_memory_pressure(args):
    experiment_dirpath = f"{args.output_dir}/{args.experiment_id}"
    df = pd.read_csv(f"{experiment_dirpath}/iterations-with-memory-pressure.csv")
    
    __extract_min_max_memory_usage(df)
    __extract_time_elapsed(df)
    __extract_min_max_ratio(df)


def __extract_min_max_memory_usage(df):
    experiment_dirpath = f"{args.output_dir}/{args.experiment_id}"

    df_dim_1 = df[df["varying_d1"] == True]
    df_dim_2 = df[df["varying_d2"] == True]
    df_dim_3 = df[df["varying_d3"] == True]

    shapes_dim_1 = df_dim_1["d1"].unique()
    shapes_dim_2 = df_dim_2["d2"].unique()
    shapes_dim_3 = df_dim_3["d3"].unique()

    if len(shapes_dim_1) > 0:
        min_dim_1 = df_dim_1.groupby("d1")["final_memory_usage_kb"].min()
        max_dim_1 = df_dim_1.groupby("d1")["final_memory_usage_kb"].max()

        plt.plot(shapes_dim_1, min_dim_1, label="Min memory used for dimension 1", marker="o")
        plt.plot(shapes_dim_1, max_dim_1, label="Max memory used for dimension 1", marker="o")

    if len(shapes_dim_2) > 0:
        min_dim_2 = df_dim_2.groupby("d2")["final_memory_usage_kb"].min()
        max_dim_2 = df_dim_2.groupby("d2")["final_memory_usage_kb"].max()

        plt.plot(shapes_dim_2, min_dim_2, label="Min memory used for dimension 2", marker="o")
        plt.plot(shapes_dim_2, max_dim_2, label="Max memory used for dimension 2", marker="o")
        
    if len(shapes_dim_3) > 0:
        min_dim_3 = df_dim_3.groupby("d3")["final_memory_usage_kb"].min()
        max_dim_3 = df_dim_3.groupby("d3")["final_memory_usage_kb"].max()
        
        plt.plot(shapes_dim_3, min_dim_3, label="Min memory used for dimension 3", marker="o")
        plt.plot(shapes_dim_3, max_dim_3, label="Max memory used for dimension 3", marker="o")


    plt.xlabel("Input shape")
    plt.ylabel("Memory usage (KB)")
    plt.legend()
    plt.savefig(f"{experiment_dirpath}/min-max-memory-usage.png")
    plt.clf()


def __extract_time_elapsed(df):
    experiment_dirpath = f"{args.output_dir}/{args.experiment_id}"

    df_dim_1 = df[df["varying_d1"] == True]
    df_dim_2 = df[df["varying_d2"] == True]
    df_dim_3 = df[df["varying_d3"] == True]

    shapes_dim_1 = df_dim_1["d1"].unique()
    shapes_dim_2 = df_dim_2["d2"].unique()
    shapes_dim_3 = df_dim_3["d3"].unique()
    
    df_dim = df_dim_1 if len(shapes_dim_1) > 0 else df_dim_2 if len(shapes_dim_2) > 0 else df_dim_3
    dim = "d1" if len(shapes_dim_1) > 0 else "d2" if len(shapes_dim_2) > 0 else "d3"
    shapes_dim = shapes_dim_1 if len(shapes_dim_1) > 0 else shapes_dim_2 if len(shapes_dim_2) > 0 else shapes_dim_3

    df_grouped = df_dim.groupby([dim, "memory_pressure"])
    time_elapsed_data = list(df_grouped["elapsed_time"].mean().groupby(level=0).apply(list))
    memory_pressure_data = list(df_grouped["memory_pressure"].first().groupby(level=0).apply(list))


    fig, ax1 = plt.subplots()
    color = "tab:red"
    ax1.set_xlabel("Memory pressure (%)")
    ax1.set_ylabel("Time elapsed (s) - (first 3)", color=color)
    ax1.tick_params(axis="y", labelcolor=color)

    for i, time_elapsed in enumerate(time_elapsed_data[:3]):
        memory_pressure = [
            pressure * 100 for pressure in memory_pressure_data[:3][i]
        ]

        ax1.plot(
            memory_pressure,
            time_elapsed,
            label=f"Shape {shapes_dim[i]}",
            marker="o",
            color=color,
        )

    color = "tab:blue"
    ax2 = ax1.twinx()
    ax2.set_ylabel("Time elapsed (s) - (last 3)", color=color)
    ax2.tick_params(axis="y", labelcolor=color)

    for i, time_elapsed in enumerate(time_elapsed_data[-3:]):
        memory_pressure = [
            pressure * 100 for pressure in memory_pressure_data[-3:][i]
        ]

        ax2.plot(
            memory_pressure,
            time_elapsed,
            label=f"Shape {shapes_dim[i]}",
            marker="o",
            color=color,
        )

    fig.tight_layout()

    plt.savefig(f"{experiment_dirpath}/time-elapsed.png")
    plt.clf()


def __extract_min_max_ratio(df):
    experiment_dirpath = f"{args.output_dir}/{args.experiment_id}"

    df_dim_1 = df[df["varying_d1"] == True]
    df_dim_2 = df[df["varying_d2"] == True]
    df_dim_3 = df[df["varying_d3"] == True]

    shapes_dim_1 = df_dim_1["d1"].unique()
    shapes_dim_2 = df_dim_2["d2"].unique()
    shapes_dim_3 = df_dim_3["d3"].unique()
    
    df_dim = df_dim_1 if len(shapes_dim_1) > 0 else df_dim_2 if len(shapes_dim_2) > 0 else df_dim_3
    dim = "d1" if len(shapes_dim_1) > 0 else "d2" if len(shapes_dim_2) > 0 else "d3"
    shapes_dim = shapes_dim_1 if len(shapes_dim_1) > 0 else shapes_dim_2 if len(shapes_dim_2) > 0 else shapes_dim_3

    memory_used_dim = list(df_dim.groupby(dim)["final_memory_usage_kb"].apply(list))

    min_max_ratios = []
    for result in memory_used_dim:
        min_max_ratios.append(max(result) / min(result))

    plt.plot(shapes_dim, min_max_ratios, marker="o")
    plt.xlabel("Input shape")
    plt.ylabel("Allowed memory pressure")
    plt.savefig(f"{experiment_dirpath}/min-max-ratio.png")
    plt.clf()



if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--experiment-id", help="ID of the experiment", type=str, required=True
    )
    parser.add_argument(
        "--output-dir",
        help="Directory to store the results",
        type=str,
        default="/data",
    )

    args = parser.parse_args()

    run(args)
 