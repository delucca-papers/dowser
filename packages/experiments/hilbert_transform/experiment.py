import dask
import scipy
import dask.array as da
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from multiprocessing import Queue
from libs.logging import log
from experiments.value_objects import Experiment


class HilbertTransformExperiment(Experiment):
    shapes: list[tuple[int, int, int]] = [
        # Varying Dimension X
        (200, 100, 100),
        (300, 100, 100),
        (500, 100, 100),
        (800, 100, 100),
        (1300, 100, 100),
        (2100, 100, 100),
        (3400, 100, 100),
        (5500, 100, 100),
        (8900, 100, 100),
        (14400, 100, 100),
        # Varying Dimension Y
        (100, 200, 100),
        (100, 300, 100),
        (100, 500, 100),
        (100, 800, 100),
        (100, 1300, 100),
        (100, 2100, 100),
        (100, 3400, 100),
        (100, 5500, 100),
        (100, 8900, 100),
        (100, 14400, 100),
        # Varying Dimension Z
        (100, 100, 200),
        (100, 100, 300),
        (100, 100, 500),
        (100, 100, 800),
        (100, 100, 1300),
        (100, 100, 2100),
        (100, 100, 3400),
        (100, 100, 5500),
        (100, 100, 8900),
        (100, 100, 14400),
    ]

    def __init__(self):
        super().__init__("hilbert-transform")

    def _load_input_data(self, shape: tuple[int, int, int], queue: Queue) -> None:
        x = np.random.random(shape)
        darray = da.array(x)

        queue.put(darray)
        log.info("Finished loading input data")

    def _execute_experiment(self, input_data, _: Queue) -> None:
        dask.config.set(scheduler="single-threaded")

        analytical_trace = input_data.map_blocks(
            scipy.signal.hilbert, dtype=input_data.dtype
        )

        log.info("Computing trace")
        analytical_trace.compute()

    def _process_results(self):
        log.info("Processing results")
        rows = []
        columns = ["shape_dimension_value", "shape_dimension", "mean", "std_dev"]

        for shape_key, results in self.results.items():
            shape = self._get_shape_value(shape_key)
            shape_dimension = self._get_varying_dimension(shape)
            shape_dimension_value = self._get_shape_in_dimension(shape, shape_dimension)
            mean = np.mean([result["execution_max_memory_usage"] for result in results])
            std_dev = np.std(
                [result["execution_max_memory_usage"] for result in results]
            )

            rows.append([shape_dimension_value, shape_dimension, mean, std_dev])

        df = pd.DataFrame(rows, columns=columns)
        df.to_csv(self.results_path / "results.csv")

        labels_dim_x = df[df["shape_dimension"] == "x"]["shape_dimension_value"]
        means_dim_x = df[df["shape_dimension"] == "x"]["mean"]

        labels_dim_y = df[df["shape_dimension"] == "y"]["shape_dimension_value"]
        means_dim_y = df[df["shape_dimension"] == "y"]["mean"]

        labels_dim_z = df[df["shape_dimension"] == "z"]["shape_dimension_value"]
        means_dim_z = df[df["shape_dimension"] == "z"]["mean"]

        plt.plot(labels_dim_x, means_dim_x, label="Varying Dimension 1", marker="o")
        plt.plot(labels_dim_y, means_dim_y, label="Varying Dimension 2", marker="o")
        plt.plot(labels_dim_z, means_dim_z, label="Varying Dimension 3", marker="o")
        plt.xlabel("Input size")
        plt.ylabel("Max memory (MB)")
        plt.legend()
        plt.savefig(f"{self.results_path}/shape_comparisson.png")
