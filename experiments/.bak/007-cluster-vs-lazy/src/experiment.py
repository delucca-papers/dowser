from sys import argv
from helpers import get_tree_mem_usage

shape = argv[1]
initial_mem_usage = get_tree_mem_usage()

print(f"Shape: {shape}")
print(f"Initial memory usage: {initial_mem_usage} KB")


# import argparse
# import time
# import importlib


# def run(args):
#     # Create the input data
#     import dask

#     # dask.config.set(scheduler="single-threaded")
#     dask.config.set(scheduler="synchronous")

#     input = __get_data(args)
#     # Store the input data memory usage
#     input_data_memory_usage_kb = (
#         resource.getrusage(resource.RUSAGE_SELF).ru_maxrss - initial_memory_usage_kb
#     )

#     # Compute
#     attribute = importlib.import_module(f"attributes.{args.attribute}")
#     start_time = time.time()
#     attribute.run(input)
#     elapsed_time = time.time() - start_time

#     # Store the final memory usage
#     final_memory_usage_kb = (
#         resource.getrusage(resource.RUSAGE_THREAD).ru_maxrss - initial_memory_usage_kb
#     )
#     import psutil
#     import os

#     current_process = psutil.Process()
#     children = current_process.children(recursive=True)
#     selfpid = os.getpid()
#     print(f"Self pid is {selfpid}")
#     print("Self memory is:")
#     os.system(f"cat /proc/{selfpid}/status | grep VmPeak")

#     for child in children:
#         print('Child pid is {}'.format(child.pid))
#         print('Child memory is:')
#         os.system(f"cat /proc/{child.pid}/status | grep VmPeak")
#     time.sleep(100)


#     # Store the results
#     import pandas as pd

#     varying_d1 = args.d1 != args.d2 and args.d1 != args.d3
#     varying_d2 = args.d2 != args.d1 and args.d2 != args.d3
#     varying_d3 = args.d3 != args.d1 and args.d3 != args.d2

#     result_folder = os.path.join(args.output_dir, args.execution_id)
#     os.makedirs(result_folder, exist_ok=True)
#     suffix = f"-{args.output_suffix}" if args.output_suffix else ""
#     iterations_filepath = os.path.join(result_folder, f"iterations{suffix}.csv")
#     current_iteration_df = pd.DataFrame(
#         {
#             "d1": args.d1,
#             "d2": args.d2,
#             "d3": args.d3,
#             "varying_d1": varying_d1,
#             "varying_d2": varying_d2,
#             "varying_d3": varying_d3,
#             "initial_memory_usage_kb": initial_memory_usage_kb,
#             "input_data_memory_usage_kb": input_data_memory_usage_kb,
#             "final_memory_usage_kb": final_memory_usage_kb,
#             "memory_pressure": args.pressure,
#             "elapsed_time": elapsed_time,
#         },
#         index=[0],
#     )

#     if os.path.exists(iterations_filepath):
#         iterations_df = pd.read_csv(iterations_filepath)
#         iterations_df = pd.concat([iterations_df, current_iteration_df])
#     else:
#         iterations_df = current_iteration_df

#     iterations_df.to_csv(iterations_filepath, index=False)


# def __get_data(args):
#     import dask.array as da
#     import numpy as np

#     shape = (args.d1, args.d2, args.d3)
#     x = np.random.random(shape)
#     return da.array(x)


# if __name__ == "__main__":
#     parser = argparse.ArgumentParser()
#     parser.add_argument(
#         "--experiment-id", help="ID of the experiment", type=str, required=True
#     )
#     parser.add_argument(
#         "--output-suffix",
#         help="Suffix to add to the output file",
#         type=str
#     )
#     parser.add_argument(
#         "--d1", help="Amount of records on the first dimension", type=int, default=100
#     )
#     parser.add_argument(
#         "--d2", help="Amount of records on the second dimension", type=int, default=100
#     )
#     parser.add_argument(
#         "--d3", help="Amount of records on the third dimension", type=int, default=100
#     )
#     parser.add_argument(
#         "--output-dir",
#         help="Directory to store the results",
#         type=str,
#         default="/data",
#     )
#     parser.add_argument(
#         "--attribute", help="Attribute to be used", type=str, required=True, choices=["envelope", "semblance"]
#     )
#     parser.add_argument(
#         "--pressure", help="Percentage of memory pressure", type=str, default=0
#     )

#     args = parser.parse_args()

#     run(args)
