#!/bin/bash

# test TurboVNC-based container
docker run -ti --gpus all -p 5920:5900 -p 8100:8080 -e SIZEW=1024 -e SIZEH=768 -e CDEPTH=24 -e BASIC_AUTH_PASSWORD= -e PASSWD= -e NOVNC_ENABLE=true --tmpfs /dev/shm:rw --rm --name=turbo ghcr.io/km-robotics/docker-nvidia-egl-turbovnc:edge
