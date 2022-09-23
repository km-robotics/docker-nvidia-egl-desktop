#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker build --target egl-desktop -t kmr/docker-nvidia-egl-desktop:edge $DIR
docker tag kmr/docker-nvidia-egl-desktop:edge ghcr.io/km-robotics/docker-nvidia-egl-desktop:edge
docker build --target egl-onlyvgl -t kmr/docker-nvidia-egl-onlyvgl:edge $DIR
docker tag kmr/docker-nvidia-egl-onlyvgl:edge ghcr.io/km-robotics/docker-nvidia-egl-onlyvgl:edge
docker build --target egl-turbovnc -t kmr/docker-nvidia-egl-turbovnc:edge $DIR
docker tag kmr/docker-nvidia-egl-turbovnc:edge ghcr.io/km-robotics/docker-nvidia-egl-turbovnc:edge
