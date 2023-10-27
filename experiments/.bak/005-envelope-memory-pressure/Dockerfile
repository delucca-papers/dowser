FROM continuumio/miniconda3 as base

ARG SSH_KEY
ENV SSH_KEY=$SSH_KEY

WORKDIR /app

RUN pip install --upgrade pip
RUN apt-get update && \
    apt-get install -y git build-essential

COPY requirements.txt /app
RUN conda create -c rapidsai -c conda-forge -c nvidia --name default --file requirements.txt

RUN mkdir /root/.ssh/
RUN echo "$SSH_KEY" > /root/.ssh/id_rsa && \
    ssh-keyscan -p 443 ssh.github.com > /root/.ssh/known_hosts && \
    chmod 600 /root/.ssh/id_rsa

RUN conda run -n default pip3 install --extra-index-url https://test.pypi.org/simple/ XPySom-dask git+https://github.com/discovery-unicamp/dasf-core.git
RUN conda run -n default pip3 install git+ssh://git@ssh.github.com:443/discovery-unicamp/dasf-seismic.git

RUN rm -rf /root/.ssh/

RUN groupadd -g 1000 -o dowser
RUN useradd -m -u 1000 -g 1000 -o -s /bin/bash dowser
RUN chown -R 1000:1000 /app

USER 1000

FROM base as profile

COPY src/profile_mem_usage.py /app
COPY src/experiment.py /app
COPY src/envelope.py /app

ENTRYPOINT ["conda", "run", "-n", "default", "python", "/app/profile_mem_usage.py"]

FROM base as experiment

COPY src/experiment.py /app
COPY src/envelope.py /app

ENTRYPOINT ["conda", "run", "-n", "default", "python", "/app/experiment.py"]

FROM base as evaluate

WORKDIR /app
COPY src/evaluate.py /app

ENTRYPOINT ["conda", "run", "-n", "default", "python", "/app/evaluate.py"]
