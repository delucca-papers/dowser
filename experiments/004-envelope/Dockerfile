FROM nvcr.io/nvidia/pytorch:23.06-py3 as base

ARG SSH_KEY
ENV SSH_KEY=$SSH_KEY

RUN pip install --upgrade pip
RUN apt-get install -y git

RUN mkdir /root/.ssh/
RUN echo "$SSH_KEY" > /root/.ssh/id_rsa && \
    ssh-keyscan -p 443 ssh.github.com > /root/.ssh/known_hosts && \
    chmod 600 /root/.ssh/id_rsa

RUN pip3 install --extra-index-url https://test.pypi.org/simple/ XPySom-dask git+https://github.com/discovery-unicamp/dasf-core.git
RUN pip3 install git+ssh://git@ssh.github.com:443/discovery-unicamp/dasf-seismic.git

RUN rm -rf /root/.ssh/

WORKDIR /app

RUN groupadd -g 1000 -o dowser
RUN useradd -m -u 1000 -g 1000 -o -s /bin/bash dowser
RUN chown -R 1000:1000 /app

COPY requirements.txt /app

RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt --force-reinstall

USER 1000

FROM base as experiment

COPY src/experiment.py /app
COPY src/envelope.py /app

ENTRYPOINT ["python", "/app/experiment.py"]

FROM base as evaluate

WORKDIR /app
COPY src/evaluate.py /app

ENTRYPOINT ["python", "/app/evaluate.py"]
