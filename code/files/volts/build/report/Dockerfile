FROM python:3.7-buster
LABEL maintainer="Ihor Olkhovskyi <ihor.olkhovskyi@cern.ch>"

COPY requirements.txt /root/requirements.txt

RUN mkdir -p /opt/scenarios && \
    mkdir -p /opt/report && \
    pip install -r /root/requirements.txt

COPY report.py /root/report.py
COPY entrypoint.report.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

WORKDIR /root

ENTRYPOINT ["/docker-entrypoint.sh"]
