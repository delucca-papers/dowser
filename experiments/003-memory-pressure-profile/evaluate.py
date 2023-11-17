import os
import sys
import pandas as pd
import matplotlib.pyplot as plt


def run(output_dir):
    os.makedirs(f"{output_dir}/graphs", exist_ok=True)

    df = __build_dataframe(output_dir)
    print(df)


def __build_dataframe(output_dir):
    df_input_attributes = pd.read_csv(
        f"{output_dir}/execution-input-parameters-reference.csv"
    )
    df_memory_pressure = pd.read_csv(f"{output_dir}/memory-pressure.csv")
    df_memory_usage = pd.read_csv(f"{output_dir}/memory-usage.csv")

    df = pd.merge(df_memory_usage, df_input_attributes, on="Execution ID")
    df = pd.merge(df, df_memory_pressure, on="Execution ID")
    df = df.rename(columns=lambda x: x.strip())
    df = df[df["Exit code"] != 137]
    df = df.drop(["Execution ID", "Shape D2", "Shape D3", "Exit code"], axis=1)
    df = df.sort_values("Memory pressure", ascending=False).drop_duplicates(
        ["Attribute name", "Shape D1"]
    )

    return df


if __name__ == "__main__":
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "/output"

    plt.figure(figsize=(9, 9))

    run(output_dir)
