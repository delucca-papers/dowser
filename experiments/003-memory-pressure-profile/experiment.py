from sys import argv
from common.task import run_attribute


if __name__ == "__main__":
    d1 = int(argv[1])
    d2 = int(argv[2])
    d3 = int(argv[3])
    attribute_name = str(argv[4])

    print(f"Capture INPUT_PARAMETERS {d1} {d2} {d3} {attribute_name}")

    run_attribute(d1, d2, d3, attribute_name, single_threaded=True)
