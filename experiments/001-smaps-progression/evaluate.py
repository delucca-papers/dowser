import os
import pandas as pd
import matplotlib.pyplot as plt

from datetime import datetime


def run():
    plt.figure(figsize=(18, 9))
    os.makedirs("/output/graphs", exist_ok=True)

    df_smaps = pd.read_csv("/output/smaps-history.csv")

    rss_data, shared_data, swap_data = __prepare_data(df_smaps)

    __plot_all(rss_data, shared_data, swap_data)
    __plot_only_client(rss_data, shared_data, swap_data)
    __plot_only_server(rss_data, shared_data, swap_data)
    __plot_only_client_rss(rss_data)
    __plot_only_server_rss(rss_data)
    __plot_only_server_shared(shared_data)
    __plot_only_server_swap(swap_data)


def __prepare_data(df_smaps):
    rss_data = {}
    shared_data = {}
    swap_data = {}

    for _, row in df_smaps.iterrows():
        timestamp = datetime.fromtimestamp(row[1]).strftime("%H:%M:%S")
        pid = int(row[2])
        process_type = row[3].strip()
        rss = int(row[4])
        shared = int(row[5]) + int(row[6])
        swap = int(row[7])
        row_key = "client" if process_type == "client" else pid

        row_rss_timestamps = (
            [timestamp]
            if row_key not in rss_data
            else rss_data[row_key]["timestamps"] + [timestamp]
        )
        row_rss_data = (
            [rss] if row_key not in rss_data else rss_data[row_key]["data"] + [rss]
        )

        row_shared_timestamps = (
            [timestamp]
            if row_key not in shared_data
            else shared_data[row_key]["timestamps"] + [timestamp]
        )
        row_shared_data = (
            [shared]
            if row_key not in shared_data
            else rss_data[row_key]["data"] + [shared]
        )

        row_swap_timestamps = (
            [timestamp]
            if row_key not in swap_data
            else swap_data[row_key]["timestamps"] + [timestamp]
        )
        row_swap_data = (
            [swap] if row_key not in swap_data else rss_data[row_key]["data"] + [swap]
        )

        if row_key not in rss_data:
            rss_data[row_key] = {}
            shared_data[row_key] = {}
            swap_data[row_key] = {}

        rss_data[row_key].update(
            {"timestamps": row_rss_timestamps, "data": row_rss_data}
        )
        shared_data[row_key].update(
            {"timestamps": row_shared_timestamps, "data": row_shared_data}
        )
        swap_data[row_key].update(
            {"timestamps": row_swap_timestamps, "data": row_swap_data}
        )

    return rss_data, shared_data, swap_data


def __plot_all(rss_data, shared_data, swap_data):
    data_to_plot = [
        ("Rss", rss_data.items()),
        ("Shared", shared_data.items()),
        ("Swap", swap_data.items()),
    ]

    for label, data in data_to_plot:
        for key, value in data:
            plt.plot(value["timestamps"], value["data"], label=f"{key}_{label}")

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history.png")
    plt.clf()


def __plot_only_client(rss_data, shared_data, swap_data):
    data_to_plot = [
        ("Rss", rss_data.items()),
        ("Shared", shared_data.items()),
        ("Swap", swap_data.items()),
    ]

    for label, data in data_to_plot:
        for key, value in data:
            if key == "client":
                plt.plot(value["timestamps"], value["data"], label=f"{key}_{label}")

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-client.png")
    plt.clf()


def __plot_only_server(rss_data, shared_data, swap_data):
    data_to_plot = [
        ("Rss", rss_data.items()),
        ("Shared", shared_data.items()),
        ("Swap", swap_data.items()),
    ]

    for label, data in data_to_plot:
        for key, value in data:
            if key != "client":
                plt.plot(value["timestamps"], value["data"], label=f"{key}_{label}")

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-server.png")
    plt.clf()


def __plot_only_client_rss(rss_data):
    for key, value in rss_data.items():
        if key == "client":
            plt.plot(value["timestamps"], value["data"], label=key)

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-client-rss.png")
    plt.clf()


def __plot_only_server_rss(rss_data):
    for key, value in rss_data.items():
        if key != "client":
            plt.plot(value["timestamps"], value["data"], label=key)

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-server-rss.png")
    plt.clf()


def __plot_only_server_shared(shared_data):
    for key, value in shared_data.items():
        if key != "client":
            plt.plot(value["timestamps"], value["data"], label=key)

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-server-shared.png")
    plt.clf()


def __plot_only_server_swap(swap_data):
    for key, value in swap_data.items():
        if key != "client":
            plt.plot(value["timestamps"], value["data"], label=key)

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-server-swap.png")
    plt.clf()


if __name__ == "__main__":
    run()
