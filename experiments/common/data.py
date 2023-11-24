def generate(d1: int, d2: int, d3: int):
    import dask.array as da
    import numpy as np

    shape = (d1, d2, d3)
    x = np.random.random(shape)
    return da.from_array(x, chunks=x.shape)


def load(dataset_name: str, chunk_size: int):
    from importlib import import_module

    dataset_component_name_hashtable = {
        "f3": "F3",
        "parihaka": "ParihakaFull",
    }
    dataset_component_name = dataset_component_name_hashtable[dataset_name]

    dataset_component = getattr(
        import_module(f"dasf_seismic.datasets"), dataset_component_name
    )
    dataset = dataset_component(chunks={"iline": chunk_size})
    dataset._lazy_load_cpu()
    print(dataset.shape)

    return dataset._data[0:chunk_size]
