def run():
    from common import data, report

    report.store_mem_usage("INITIAL")

    input = data.generate(1000, 1000, 1000)
    report.store_mem_usage("DATA")

    from common.cluster import build_pipeline
    from common.attributes import envelope

    pipeline = build_pipeline()
    envelope.run(input, pipeline)
    report.store_mem_usage("COMPUTING")


if __name__ == "__main__":
    run()
