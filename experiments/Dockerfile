FROM continuumio/miniconda3

ARG SSH_KEY
ARG UID=1000
ARG GID=1000

WORKDIR /experiment

RUN pip install --upgrade pip
RUN apt-get update && \
    apt-get install -y git build-essential

COPY requirements.txt /experiment
RUN conda create -c rapidsai -c conda-forge -c nvidia --name default --file requirements.txt

RUN mkdir /root/.ssh/
RUN echo "$SSH_KEY" > /root/.ssh/id_rsa && \
    ssh-keyscan -p 443 ssh.github.com > /root/.ssh/known_hosts && \
    chmod 600 /root/.ssh/id_rsa

RUN conda run -n default pip3 install --extra-index-url https://test.pypi.org/simple/ XPySom-dask git+https://github.com/discovery-unicamp/dasf-core.git
RUN conda run -n default pip3 install git+ssh://git@ssh.github.com:443/discovery-unicamp/dasf-seismic.git

RUN rm -rf /root/.ssh/

RUN groupadd -g ${GID} -o dowser
RUN useradd -m -u ${UID} -g ${GID} -o -s /bin/bash dowser
RUN chown -R ${UID}:${GID} /experiment

USER ${UID}

COPY --chown=${UID}:${GID} common /experiment/common
COPY --chown=${UID}:${GID} 001-smaps-progression /experiment/001-smaps-progression

ENV PYTHONPATH "${PYTHONPATH}:/experiment"

ENTRYPOINT ["conda", "run", "-n", "default", "python", "-m"]