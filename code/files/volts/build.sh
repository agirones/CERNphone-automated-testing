#!/bin/sh

if [ "$1" = "-r" ]; then
    docker rmi $(docker images | grep prepare | awk '{ print $3 }')
    docker rmi $(docker images | grep vp | awk '{ print $3 }')
    docker rmi $(docker images | grep report | awk '{ print $3 }')
    docker rmi $(docker images | grep database | awk '{ print $3 }')
fi

docker build --file build/prepare/Dockerfile --tag registry.cern.ch/volts/prepare build/prepare
docker build --file build/vp/Dockerfile --tag registry.cern.ch/volts/vp build/vp
docker build --file build/report/Dockerfile --tag registry.cern.ch/volts/report build/report
docker build --file build/database/Dockerfile --tag registry.cern.ch/volts/database build/database
