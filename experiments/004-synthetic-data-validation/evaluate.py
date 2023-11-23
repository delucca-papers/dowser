import os
import sys
import pandas as pd
import matplotlib.pyplot as plt


def run(output_dir):
    os.makedirs(f"{output_dir}/graphs", exist_ok=True)

    df = __build_dataframe(output_dir)
    data = __prepare_data(df)

    __save_summary(df, output_dir)
    __plot_all(data, output_dir)


def __prepare_data(df):
    data = {}

    for row_name, row in df.iterrows():
        attribute = row_name[0].strip()
        shape = row_name[1]
        memory_usage = row["Final memory usage"]

        if attribute not in data:
            data[attribute] = {"shapes": [], "memory_usage": []}

        data[attribute]["shapes"].append(shape)
        data[attribute]["memory_usage"].append(memory_usage)

    return data


def __plot_all(data, output_dir):
    for key, value in data.items():
        plt.plot(value["shapes"], value["memory_usage"], label=key)

    plt.xlabel("Shape")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig(f"{output_dir}/graphs/overview.png")
    plt.clf()


def __save_summary(df, output_dir):
    df.to_csv(f"{output_dir}/memory-usage-summary.csv")


def __build_dataframe(output_dir):
    df_input_attributes = pd.read_csv(
        f"{output_dir}/execution-input-parameters-reference.csv"
    )
    df_memory_usage = pd.read_csv(f"{output_dir}/memory-usage.csv")

    df = pd.merge(df_memory_usage, df_input_attributes, on="Execution ID")
    df = df.rename(columns=lambda x: x.strip())
    df = df.drop(["Execution ID", "Shape D2", "Shape D3"], axis=1)
    df = df.groupby(["Attribute name", "Shape D1"]).mean()

    return df


if __name__ == "__main__":
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "/output"

    plt.figure(figsize=(9, 9))

    run(output_dir)
