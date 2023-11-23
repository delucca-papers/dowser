FROM continuumio/miniconda3:23.5.2-0-alpine

ARG SSH_KEY
ARG UID=1000
ARG GID=984
ARG UNAME=dowser
ARG GNAME=dowser_users
ARG DIRNAME=experiments

ENV HOME=/home/${UNAME}
ENV BASEDIR=${HOME}/${DIRNAME}

RUN apk update && \
    apk add git g++ make openssh-client && \
    pip install --upgrade pip

COPY requirements.txt ${BASEDIR}/requirements.txt
RUN conda config --set channel_priority flexible && \
    conda install -n base conda-libmamba-solver && \
    conda config --set solver libmamba && \
    conda create -c rapidsai -c conda-forge -c nvidia --name experiments --file ${BASEDIR}/requirements.txt -y

RUN if getent passwd ${UID} >/dev/null; then \
    deluser $(getent passwd ${UID} | cut -d: -f1); fi && \
    if getent group ${GID} >/dev/null; then \
    delgroup $(getent group ${GID} | cut -d: -f1); fi && \
    addgroup --system --gid ${GID} ${GNAME} && \
    adduser --system --disabled-password --home /home/${UNAME} --uid ${UID} --ingroup ${GNAME} ${UNAME}
RUN chown -R ${UID}:${GID} ${HOME}
USER ${UID}
WORKDIR ${BASEDIR}

RUN mkdir ${HOME}/.ssh/ && \
    echo "$SSH_KEY" > ${HOME}/.ssh/id_rsa && \
    ssh-keyscan -p 443 ssh.github.com > ${HOME}/.ssh/known_hosts && \
    chmod 600 ${HOME}/.ssh/id_rsa && \
    conda run -n experiments pip3 install --extra-index-url https://test.pypi.org/simple/ XPySom-dask git+https://github.com/discovery-unicamp/dasf-core.git && \
    conda run -n experiments pip3 install git+ssh://git@ssh.github.com:443/discovery-unicamp/dasf-seismic.git && \
    conda run -n experiments pip3 install dask-cuda==23.8.0 && \
    rm -rf ${HOME}/.ssh

COPY --chown=${UID}:${GID} common ${BASEDIR}/common
COPY --chown=${UID}:${GID} 001-smaps-progression ${BASEDIR}/001-smaps-progression
COPY --chown=${UID}:${GID} 002-memory-usage-profile ${BASEDIR}/002-memory-usage-profile
COPY --chown=${UID}:${GID} 003-memory-pressure-profile ${BASEDIR}/003-memory-pressure-profile
COPY --chown=${UID}:${GID} 004-synthetic-data-validation ${BASEDIR}/004-synthetic-data-validation

ENV PYTHONPATH "${PYTHONPATH}:${BASEDIR}"

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "experiments", "python", "-u", "-m"]
