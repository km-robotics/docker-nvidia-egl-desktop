#!/bin/bash

docker tag kmr/docker-nvidia-egl-desktop:edge ghcr.io/km-robotics/docker-nvidia-egl-desktop:edge
docker push ghcr.io/km-robotics/docker-nvidia-egl-desktop:edge
docker tag kmr/docker-nvidia-egl-onlyvgl:edge ghcr.io/km-robotics/docker-nvidia-egl-onlyvgl:edge
docker push ghcr.io/km-robotics/docker-nvidia-egl-onlyvgl:edge
