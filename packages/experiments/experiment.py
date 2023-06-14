from enum import Enum

from .hilbert_transform import HilbertTransformExperiment


class Experiment(Enum):
    hilbert_transform = "hilbert_transform"

    __experiment_hashmap = {"hilbert_transform": HilbertTransformExperiment}

    def __str__(self):
        return self.value

    def start(self):
        experiment = self.__experiment_hashmap[self.value]()
        experiment.start()
