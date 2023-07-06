FROM python:3.11.3

RUN pip install --upgrade pip

WORKDIR /app

RUN groupadd -g 1000 -o dowser
RUN useradd -m -u 1000 -g 1000 -o -s /bin/bash dowser
RUN chown -R 1000:1000 /app

COPY requirements.txt /app

RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt

USER 1000

COPY src/code.py /app
ENTRYPOINT ["python", "/app/code.py"]
