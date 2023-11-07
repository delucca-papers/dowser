def generate(d1: int, d2: int, d3: int):
    import dask.array as da
    import numpy as np

    shape = (d1, d2, d3)
    x = np.random.random(shape)
    return da.array(x)
