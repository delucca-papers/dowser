def get_tree_mem_usage(pid: int | None = None, type: str = "peak") -> int:
    from psutil import Process

    type_handler = type_hashmap[type]

    self = Process(pid)
    print(self.memory_full_info())
    children = self.children(recursive=True)
    mem_usage = 0
    mem_usage += type_handler(self.pid)

    for child in children:
        mem_usage += type_handler(child.pid)

    return mem_usage


def get_peak_mem_usage(pid: int) -> int:
    return int(get_proc_line_value(pid, "VmPeak"))


def get_proc_line_value(pid: int, key: str):
    with open(f"/proc/{pid}/status") as f:
        for line in f:
            if line.startswith(key):
                return line.split(":")[1].strip().split(" ")[0]


type_hashmap = {"peak": get_peak_mem_usage}
