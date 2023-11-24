from sys import argv
from common.task import run_attribute


if __name__ == "__main__":
    d1 = int(argv[1])
    d2 = int(argv[2])
    d3 = int(argv[3])
    num_workers = int(argv[4])

    run_attribute(d1, d2, d3, "envelope", n_workers=num_workers)
