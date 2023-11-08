def store_mem_usage(type: str):
    import signal
    from time import sleep

    waiting_for_signal = True

    def handle_signal(signum, frame):
        print(f"Signal received {signum}")
        print(f"Frame {frame}")

        nonlocal waiting_for_signal
        waiting_for_signal = False

    signal.signal(signal.SIGCONT, handle_signal)
    print(f"Capture {type}_MEM_USAGE")

    while waiting_for_signal:
        sleep(1)
