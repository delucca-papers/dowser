import argparse

from .experiment import Experiment


def start_experiment():
    arguments = __parse_arguments()
    arguments.experiment.start()


def __parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Launch experiments executed during the research"
    )
    parser.add_argument(
        "experiment",
        type=Experiment,
        help="the name of the experiment to execute",
        choices=list(Experiment),
    )

    return parser.parse_args()
