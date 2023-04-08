#!/bin/bash

docker tag kmr/docker-nvidia-egl-desktop:edge ghcr.io/km-robotics/docker-nvidia-egl-desktop:edge
docker push ghcr.io/km-robotics/docker-nvidia-egl-desktop:edge
docker tag kmr/docker-nvidia-egl-onlyvgl:edge ghcr.io/km-robotics/docker-nvidia-egl-onlyvgl:edge
docker push ghcr.io/km-robotics/docker-nvidia-egl-onlyvgl:edge
docker tag kmr/docker-nvidia-egl-turbovnc:edge ghcr.io/km-robotics/docker-nvidia-egl-turbovnc:edge
docker push ghcr.io/km-robotics/docker-nvidia-egl-turbovnc:edge
docker tag kmr/docker-nvidia-egl-kasmvnc:edge ghcr.io/km-robotics/docker-nvidia-egl-kasmvnc:edge
docker push ghcr.io/km-robotics/docker-nvidia-egl-kasmvnc:edge
