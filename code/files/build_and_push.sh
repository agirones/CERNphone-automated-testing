#!/bin/sh

if [ "$1" = "-r" ]; then
    docker rmi $(docker images | grep prepare | awk '{ print $3 }')
    docker rmi $(docker images | grep vp | awk '{ print $3 }')
    docker rmi $(docker images | grep report | awk '{ print $3 }')
    docker rmi $(docker images | grep database | awk '{ print $3 }')
fi

docker build --file build/prepare/Dockerfile --tag registry.cern.ch/volts/prepare:latest build/prepare
docker build --file build/vp/Dockerfile --tag registry.cern.ch/volts/vp:latest build/vp
docker build --file build/report/Dockerfile --tag registry.cern.ch/volts/report:latest build/report
docker build --file build/database/Dockerfile --tag registry.cern.ch/volts/database:latest build/database

docker push registry.cern.ch/volts/prepare:latest
docker push registry.cern.ch/volts/vp:latest
docker push registry.cern.ch/volts/report:latest
docker push registry.cern.ch/volts/database:latest
