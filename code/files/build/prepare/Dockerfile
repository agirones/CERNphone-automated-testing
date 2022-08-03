FROM python:3.7-buster
LABEL maintainer="Ihor Olkhovskyi <ihor.olkhovskyi@cern.ch>"

COPY requirements.txt /root/requirements.txt

RUN mkdir -p /opt/input && \
    mkdir -p /opt/output && \
    pip install -r /root/requirements.txt

COPY prepare.py /root/prepare.py
COPY entrypoint.prepare.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

VOLUME ["/opt" ]

WORKDIR /root

ENTRYPOINT ["/docker-entrypoint.sh"]
