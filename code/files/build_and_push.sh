#!/bin/sh

if [ "$1" = "-r" ]; then
    docker rmi $(docker images | grep prepare | awk '{ print $1 }')
    docker rmi $(docker images | grep vp | awk '{ print $1 }')
    docker rmi $(docker images | grep report | awk '{ print $1 }')
    docker rmi $(docker images | grep database | awk '{ print $1 }')
fi

docker build --file build/prepare/Dockerfile --tag gitlab-registry.cern.ch/cernphone/functional-testing/prepare:latest build/prepare
docker build --file build/vp/Dockerfile --tag gitlab-registry.cern.ch/cernphone/functional-testing/vp:latest build/vp
docker build --file build/report/Dockerfile --tag gitlab-registry.cern.ch/cernphone/functional-testing/report:latest build/report
docker build --file build/database/Dockerfile --tag gitlab-registry.cern.ch/cernphone/functional-testing/database:latest build/database

docker push gitlab-registry.cern.ch/cernphone/functional-testing/prepare:latest
docker push gitlab-registry.cern.ch/cernphone/functional-testing/vp:latest
docker push gitlab-registry.cern.ch/cernphone/functional-testing/report:latest
docker push gitlab-registry.cern.ch/cernphone/functional-testing/database:latest
