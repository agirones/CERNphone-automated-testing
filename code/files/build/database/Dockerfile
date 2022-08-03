FROM python:3.7-buster
LABEL maintainer="Ihor Olkhovskyi <ihor.olkhovskyi@cern.ch>"

COPY requirements.txt /root/requirements.txt

RUN mkdir -p /xml && \
    pip install -r /root/requirements.txt

COPY database.py /root/database.py
COPY entrypoint.database.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

VOLUME ["/xml" ]

WORKDIR /root

ENTRYPOINT ["/docker-entrypoint.sh"]
