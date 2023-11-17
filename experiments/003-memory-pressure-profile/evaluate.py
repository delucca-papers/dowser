import os
import sys
import statistics
import pandas as pd
import matplotlib.pyplot as plt


def run(output_dir):
    os.makedirs(f"{output_dir}/graphs", exist_ok=True)

    df = __build_dataframe(output_dir)
    data = __prepare_data(df)

    __plot_min_memory_usage(data, output_dir)
    __plot_maximum_allowed_pressure(data, output_dir)
    __plot_execution_time_delta(data, output_dir)
    __plot_execution_time_stdev(data, output_dir)


def __prepare_data(df):
    data = {}

    for _, row in df.iterrows():
        attribute = row["Attribute name"].strip()
        shape = row["Shape D1"]
        memory_usage = row["Final memory usage"]
        pressure = row["Memory pressure"]
        execution_time = row["Execution time"]

        if attribute not in data:
            data[attribute] = {}

        if shape not in data[attribute]:
            data[attribute][shape] = {
                "memory_usage": [],
                "pressure": [],
                "execution_time": [],
            }

        data[attribute][shape]["memory_usage"].append(memory_usage)
        data[attribute][shape]["pressure"].append(pressure)
        data[attribute][shape]["execution_time"].append(execution_time)

    return data


def __plot_min_memory_usage(data, output_dir):
    for attribute_name, results in data.items():
        shapes = results.keys()
        max_memory_usages = [results[shape]["memory_usage"][-1] for shape in shapes]
        zipped_results = zip(shapes, max_memory_usages)

        sorted_zipped_results = sorted(zipped_results, key=lambda x: x[0])
        sorted_shapes = [x[0] for x in sorted_zipped_results]
        sorted_memory_usage = [x[1] for x in sorted_zipped_results]

        plt.plot(sorted_shapes, sorted_memory_usage, label=attribute_name)

    plt.xlabel("Shape")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig(f"{output_dir}/graphs/min-memory-usage.png")
    plt.clf()


def __plot_maximum_allowed_pressure(data, output_dir):
    for attribute_name, results in data.items():
        shapes = results.keys()
        max_pressure = [results[shape]["pressure"][-1] for shape in shapes]
        zipped_results = zip(shapes, max_pressure)

        sorted_zipped_results = sorted(zipped_results, key=lambda x: x[0])
        sorted_shapes = [x[0] for x in sorted_zipped_results]
        sorted_pressure = [x[1] for x in sorted_zipped_results]

        plt.plot(sorted_shapes, sorted_pressure, label=attribute_name)

    plt.xlabel("Shape")
    plt.ylabel("Maximum allowed memory pressure (%)")
    plt.legend()
    plt.savefig(f"{output_dir}/graphs/max-allowed-pressure.png")
    plt.clf()


def __plot_execution_time_delta(data, output_dir):
    plt.ylim(0, 100)

    for attribute_name, results in data.items():
        shapes = results.keys()
        execution_time_percentage_difference = [
            (
                results[shape]["execution_time"][-1]
                * 100
                / results[shape]["execution_time"][0]
            )
            - 100
            for shape in shapes
        ]
        zipped_results = zip(shapes, execution_time_percentage_difference)

        sorted_zipped_results = sorted(zipped_results, key=lambda x: x[0])
        sorted_shapes = [x[0] for x in sorted_zipped_results]
        sorted_execution_time_percentage_difference = [
            x[1] for x in sorted_zipped_results
        ]

        plt.plot(
            sorted_shapes,
            sorted_execution_time_percentage_difference,
            label=attribute_name,
        )

    plt.xlabel("Shape")
    plt.ylabel("Execution time (δ)")
    plt.legend()
    plt.savefig(f"{output_dir}/graphs/execution-time-delta.png")
    plt.clf()


def __plot_execution_time_stdev(data, output_dir):
    for attribute_name, results in data.items():
        shapes = results.keys()
        execution_time_percentage_stdev = [
            statistics.stdev(results[shape]["execution_time"]) for shape in shapes
        ]
        zipped_results = zip(shapes, execution_time_percentage_stdev)

        sorted_zipped_results = sorted(zipped_results, key=lambda x: x[0])
        sorted_shapes = [x[0] for x in sorted_zipped_results]
        sorted_execution_time_stdev = [x[1] for x in sorted_zipped_results]

        plt.plot(
            sorted_shapes,
            sorted_execution_time_stdev,
            label=attribute_name,
        )

    plt.xlabel("Shape")
    plt.ylabel("Execution time (σ)")
    plt.legend()
    plt.savefig(f"{output_dir}/graphs/execution-time-stdev.png")
    plt.clf()


def __build_dataframe(output_dir):
    df_input_attributes = pd.read_csv(
        f"{output_dir}/execution-input-parameters-reference.csv"
    )
    df_memory_pressure = pd.read_csv(f"{output_dir}/memory-pressure.csv")
    df_memory_usage = pd.read_csv(f"{output_dir}/memory-usage.csv")
    df_execution_time = pd.read_csv(f"{output_dir}/execution-time.csv")

    df = pd.merge(df_memory_usage, df_input_attributes, on="Execution ID")
    df = pd.merge(df, df_memory_pressure, on="Execution ID")
    df = pd.merge(df, df_execution_time, on="Execution ID")
    df = df.rename(columns=lambda x: x.strip())
    df = df[df["Exit code"] != 137]
    df = df.drop(["Execution ID", "Shape D2", "Shape D3", "Exit code"], axis=1)

    return df


if __name__ == "__main__":
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "/output"

    plt.figure(figsize=(9, 9))

    run(output_dir)
