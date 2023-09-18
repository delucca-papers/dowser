import pandas as pd
import matplotlib.pyplot as plt

hil_dirpath = "001-hilbert-transform/results/20230706142832"
env_dirpath = "004-envelope/results/20230825112141"

df_hil = pd.read_csv(f"{hil_dirpath}/iterations.csv")
df_env = pd.read_csv(f"{env_dirpath}/iterations.csv")

df_hil = df_hil[df_hil["varying_d3"] == True]
df_env = df_env[df_env["varying_d3"] == True]

shapes_hil = df_hil["d3"].unique()
shapes_env = df_env["d3"].unique()

means_hil = df_hil.groupby("d3")["final_memory_usage_kb"].mean()
means_env = df_env.groupby("d3")["final_memory_usage_kb"].mean()

plt.plot(shapes_hil, means_hil, label="Hilbert Transform", marker="o")
plt.plot(shapes_env, means_env, label="Envelope", marker="o")
plt.xlabel("Input shape")
plt.ylabel("Max memory usage (KB)")
plt.legend()
plt.savefig("result.png")
