import argparse
import pandas as pd
import matplotlib.pyplot as plt


def run(args):
    experiment_dirpath = f"{args.output_dir}/{args.execution_id}"
    df = pd.read_csv(f"{experiment_dirpath}/iterations.csv")

    df_dim_1 = df[df["varying_d1"] == True]
    df_dim_2 = df[df["varying_d2"] == True]
    df_dim_3 = df[df["varying_d3"] == True]

    shapes_dim_1 = df_dim_1["d1"].unique()
    shapes_dim_2 = df_dim_2["d2"].unique()
    shapes_dim_3 = df_dim_3["d3"].unique()

    means_dim_1 = df_dim_1.groupby("d1")["final_memory_usage_kb"].mean()
    means_dim_2 = df_dim_2.groupby("d2")["final_memory_usage_kb"].mean()
    means_dim_3 = df_dim_3.groupby("d3")["final_memory_usage_kb"].mean()

    plt.plot(shapes_dim_1, means_dim_1, label="Varying Dimension 1", marker="o")
    plt.plot(shapes_dim_2, means_dim_2, label="Varying Dimension 2", marker="o")
    plt.plot(shapes_dim_3, means_dim_3, label="Varying Dimension 3", marker="o")
    plt.xlabel("Input shape")
    plt.ylabel("Max memory usage (KB)")
    plt.legend()
    plt.savefig(f"{experiment_dirpath}/result.png")


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
