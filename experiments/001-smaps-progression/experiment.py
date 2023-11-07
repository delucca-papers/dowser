def run():
    from common import data

    input = data.generate(1000, 1000, 1000)

    from common.cluster import build_pipeline
    from common.attributes import envelope

    pipeline = build_pipeline()
    result = envelope.run(input, pipeline)

    print(result)


if __name__ == "__main__":
    run()
