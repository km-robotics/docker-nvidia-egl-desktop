#!/bin/bash

# test TurboVNC-based container
docker run -ti --gpus all -p 5920:5900 -p 8100:8080 -e SIZEW=1024 -e SIZEH=768 -e CDEPTH=24 -e BASIC_AUTH_PASSWORD= -e PASSWD= -e NOVNC_ENABLE=true --tmpfs /dev/shm:rw --rm --name=turbo ghcr.io/km-robotics/docker-nvidia-egl-turbovnc:edge

# test KasmVNC-based container
docker run -ti --gpus all -p 8443:8443/tcp -p 8443:8443/udp -e SIZEW=1024 -e SIZEH=768 -e CDEPTH=24 -e BASIC_AUTH_PASSWORD= -e PASSWD= --tmpfs /dev/shm:rw --rm --name=kasm ghcr.io/km-robotics/docker-nvidia-egl-kasmvnc:edge
