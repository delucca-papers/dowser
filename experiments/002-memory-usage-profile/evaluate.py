import os
import pandas as pd
import matplotlib.pyplot as plt

OUTPUT_DIR = "/output"
FIGURE_SIZE = (9, 9)


def run():
    plt.figure(figsize=FIGURE_SIZE)
    os.makedirs(f"{OUTPUT_DIR}/graphs", exist_ok=True)

    df = __build_dataframe()
    data = __prepare_data(df)

    __plot_all(data)


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


def __plot_all(data):
    for key, value in data.items():
        plt.plot(value["shapes"], value["memory_usage"], label=key)

    plt.xlabel("Shape")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig(f"{OUTPUT_DIR}/graphs/overview.png")
    plt.clf()


def __build_dataframe():
    df_input_attributes = pd.read_csv(
        f"{OUTPUT_DIR}/execution-input-parameters-reference.csv"
    )
    df_memory_usage = pd.read_csv(f"{OUTPUT_DIR}/memory-usage.csv")

    df = pd.merge(df_memory_usage, df_input_attributes, on="Execution ID")
    df = df.rename(columns=lambda x: x.strip())
    df = df.drop(["Execution ID", "Shape D2", "Shape D3"], axis=1)
    df = df.groupby(["Attribute name", "Shape D1"]).mean()

    return df


if __name__ == "__main__":
    run()
