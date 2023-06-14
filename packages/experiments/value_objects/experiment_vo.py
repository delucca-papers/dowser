import time

from multiprocessing import Process, Queue
from abc import ABC, abstractmethod
from typing import Any, Literal
from ulid import ulid
from datetime import datetime
from pathlib import Path
from memory_profiler import memory_usage
from libs.logging import log
from libs.logging.history import store_logs


class Experiment(ABC):
    id: str
    name: str
    timestamp: str
    shapes: list[tuple[int, int, int]]
    results_path: Path
    results: dict[str, list[dict]] = {}

    @abstractmethod
    def _load_input_data(self, shape: tuple[int, int, int], queue: Queue) -> None:
        ...

    @abstractmethod
    def _execute_experiment(self, input_data: Any, Queue: Queue) -> None:
        ...

    @abstractmethod
    def _process_results(self) -> None:
        ...

    def __init__(self, name: str):
        self.name = name
        self.id = self.__generate_id()
        self.timestamp = self.__get_timestamp()

        self.__setup_experiment()

    def start(self, num_samples: int = 35) -> None:
        for shape in self.shapes:
            log.info("================================")
            log.info(f"Executing experiments for shape {shape}")

            for i in range(num_samples):
                log.info("---------------------------")
                log.info(f"Executing iteration {i}")
                queue = Queue()

                inp_p = Process(target=self._load_input_data, args=(shape, queue))
                [inp_mem_usage, inp_data] = self.__get_results_from_process(
                    inp_p, queue
                )

                exp_p = Process(target=self._execute_experiment, args=(inp_data, queue))
                [exp_mem_usage, _] = self.__get_results_from_process(exp_p, queue)

                self.__store_results(shape, inp_mem_usage, exp_mem_usage)

                log.info("Finished executing iteration")

        self._process_results()

    @property
    def prefix(self):
        return "-".join([self.name, self.id, self.timestamp])

    def __generate_id(self) -> str:
        return ulid()

    def __get_timestamp(self) -> str:
        return datetime.now().strftime("%Y-%m-%d-%H-%M-%S")

    def __setup_experiment(self):
        self.__ensure_results_directory()
        self.__store_logs()

        log.info(f"Experiment: {self.name}")
        log.info(f"Prefix: {self.prefix}")

    def __ensure_results_directory(self):
        package_directory = Path(__file__).parent.parent.resolve()
        self.results_path = package_directory.joinpath(f"results/{self.prefix}")
        self.results_path.mkdir(parents=True, exist_ok=True)

    def __store_logs(self):
        log_filepath = str(self.results_path.joinpath("execution"))
        store_logs(log_filepath)

    def __get_results_from_process(self, process: Process, queue: Queue):
        memory_usage_history = []
        result = None
        process.start()

        while process.is_alive() and process.pid:
            memory_usage_history.extend(memory_usage(process.pid))
            process.join(timeout=0)
            result = queue.get() if queue.qsize() > 0 else None
            time.sleep(0.1)

        return memory_usage_history, result

    def __store_results(
        self,
        shape: tuple[int, int, int],
        inp_mem_usage: list,
        exp_mem_usage: list,
    ):
        shape_key = str(shape)
        shape_results = self.results.get(shape_key, [])
        shape_results.append(
            {
                "input_memory_usage": inp_mem_usage,
                "execution_memory_usage": exp_mem_usage,
            }
        )

        self.results[shape_key] = shape_results

    def _get_shape_value(self, shape: str) -> tuple[int, int, int]:
        [x, y, z] = shape.replace(" ", "")[1:-1].split(",")

        return (int(x), int(y), int(z))

    def _get_varying_dimension(
        self, shape: tuple[int, int, int]
    ) -> Literal["x", "y", "z"]:
        [x, y, z] = shape
        if x != y and x != z:
            return "x"
        elif y != x and y != z:
            return "y"
        else:
            return "z"

    def _get_shape_in_dimension(
        self, shape: tuple[int, int, int], dimension: str
    ) -> int:
        [x, y, z] = shape
        if dimension == "x":
            return x
        elif dimension == "y":
            return y
        else:
            return z
