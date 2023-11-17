def wait_for_signal(signal_type: str):
    import signal
    from time import sleep

    waiting_for_signal = True

    def handle_signal(signum, frame):
        print(f"Signal received {signum}")
        print(f"Frame {frame}")

        nonlocal waiting_for_signal
        waiting_for_signal = False

    signal.signal(signal.SIGCONT, handle_signal)
    print(f"Waiting for {signal_type} signal...")

    while waiting_for_signal:
        sleep(0.1)
