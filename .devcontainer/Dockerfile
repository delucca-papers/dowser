FROM python:3.11.5-slim

ARG POETRY_VERSION="1.4.2"

ENV POETRY_VERSION=${POETRY_VERSION}

RUN apt update
RUN pip install --upgrade pip
RUN pip install "poetry==$POETRY_VERSION"

WORKDIR /workspace

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["while sleep 1000; do :; done"]