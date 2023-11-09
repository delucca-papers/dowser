import os
import pandas as pd
import matplotlib.pyplot as plt


def run():
    df_smaps = pd.read_csv("/output/smaps-history.csv")
    os.makedirs("/output/graphs", exist_ok=True)

    rss_data = {}
    shared_data = {}
    swap_data = {}

    for _, row in df_smaps.iterrows():
        snapshot_number = int(row[1])
        pid = int(row[2])
        process_type = row[3].strip()
        rss = int(row[4])
        shared = int(row[5]) + int(row[6])
        swap = int(row[7])

        if process_type == "root":
            rss_data["root"].append(rss) if "root" in rss_data else rss_data.update(
                {"root": [rss]}
            )
            shared_data["root"].append(
                shared
            ) if "root" in shared_data else shared_data.update({"root": [shared]})
            swap_data["root"].append(swap) if "root" in swap_data else swap_data.update(
                {"root": [swap]}
            )
        else:
            if pid not in rss_data:
                rss_data.update({pid: [0 for _ in range(snapshot_number)]})
                shared_data.update({pid: [0 for _ in range(snapshot_number)]})
                swap_data.update({pid: [0 for _ in range(snapshot_number)]})
            rss_data[pid].append(rss)
            shared_data[pid].append(shared)
            swap_data[pid].append(swap)

    __plot_all(rss_data, shared_data, swap_data)
    __plot_only_children(rss_data, shared_data, swap_data)
    __plot_only_rss(rss_data)
    __plot_only_shared(shared_data)
    __plot_only_swap(swap_data)


def __plot_all(rss_data, shared_data, swap_data):
    data_to_plot = [
        ("Rss", rss_data.items()),
        ("Shared", shared_data.items()),
        ("Swap", swap_data.items()),
    ]

    for label, data in data_to_plot:
        for key, value in data:
            plt.plot(range(0, len(value)), value, label=f"{key}_{label}", marker="o")

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history.png")
    plt.clf()


def __plot_only_children(rss_data, shared_data, swap_data):
    data_to_plot = [
        ("Rss", rss_data.items()),
        ("Shared", shared_data.items()),
        ("Swap", swap_data.items()),
    ]

    for label, data in data_to_plot:
        for key, value in data:
            if key != "root":
                plt.plot(
                    range(0, len(value)), value, label=f"{key}_{label}", marker="o"
                )

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-children.png")
    plt.clf()


def __plot_only_rss(rss_data):
    for key, value in rss_data.items():
        if key != "root":
            plt.plot(range(0, len(value)), value, label=f"{key}_rss", marker="o")

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-rss.png")
    plt.clf()


def __plot_only_shared(shared_data):
    for key, value in shared_data.items():
        if key != "root":
            plt.plot(range(0, len(value)), value, label=f"{key}_shared", marker="o")

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-shared.png")
    plt.clf()


def __plot_only_swap(swap_data):
    for key, value in swap_data.items():
        if key != "root":
            plt.plot(range(0, len(value)), value, label=f"{key}_swap", marker="o")

    plt.xlabel("Snapshot")
    plt.ylabel("Memory consumption (kB)")
    plt.legend()
    plt.savefig("/output/graphs/smaps-history-swap.png")
    plt.clf()


if __name__ == "__main__":
    run()
