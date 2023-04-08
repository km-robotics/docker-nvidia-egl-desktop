ARG UBUNTU_RELEASE=22.04
ARG CUDA_VERSION=12.0.1
FROM ghcr.io/km-robotics/cudagl:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_RELEASE} AS egl-base

LABEL maintainer "https://github.com/ehfd,https://github.com/danisla"

ENV DEBIAN_FRONTEND=noninteractive

ARG UBUNTU_RELEASE
ARG CUDA_VERSION
# Make all NVIDIA GPUs visible, but we want to manually install drivers
ARG NVIDIA_VISIBLE_DEVICES=all
ARG DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES all
ENV DISPLAY :0
ENV PULSE_SERVER 127.0.0.1:4713
# has to be in a dedicated subdirectory instead of /tmp, otherwise the permissions on /tmp will change
# must do it also in entrypoint, or maybe only there?
RUN mkdir -p /tmp/xdg_runtime_dir
ENV XDG_RUNTIME_DIR=/tmp/xdg_runtime_dir

# Default environment variables (password is "mypasswd")
ENV TZ UTC
ENV VGL_DISPLAY egl
ENV SIZEW 1920
ENV SIZEH 1080
ENV REFRESH 60
ENV DPI 96
ENV CDEPTH 24
ENV PASSWD mypasswd
ENV NOVNC_ENABLE false
ENV WEBRTC_ENCODER nvh264enc
ENV WEBRTC_ENABLE_RESIZE false
ENV ENABLE_AUDIO true
ENV ENABLE_BASIC_AUTH true

# Install locales to prevent errors
RUN apt-get clean && \
    apt-get update && apt-get install --no-install-recommends -y locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Xvfb, Xfce Desktop, and others
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install --no-install-recommends -y \
        software-properties-common \
        apt-transport-https \
        apt-utils \
        build-essential \
        ca-certificates \
        cups-filters \
        cups-common \
        cups-pdf \
        curl \
        file \
        less \
        wget \
        bzip2 \
        gzip \
        p7zip-full \
        xz-utils \
        zip \
        unzip \
        zstd \
        gcc \
        git \
        jq \
        make \
        python3 \
        python3-cups \
        python3-numpy \
        mlocate \
        nano \
        vim \
        htop \
        firefox \
        qpdfview \
        xarchiver \
        adwaita-icon-theme-full \
        desktop-file-utils \
        fonts-dejavu-core \
        fonts-freefont-ttf \
        fonts-noto \
        fonts-noto-cjk \
        fonts-noto-cjk-extra \
        fonts-noto-color-emoji \
        fonts-noto-hinted \
        fonts-noto-mono \
        fonts-opensymbol \
        fonts-symbola \
        fonts-ubuntu \
        gucharmap \
        parole \
        policykit-desktop-privileges \
        libpulse0 \
        pulseaudio \
        pavucontrol \
        ristretto \
        supervisor \
        thunar \
        thunar-volman \
        thunar-archive-plugin \
        thunar-media-tags-plugin \
        net-tools \
        libgtk-3-bin \
        vainfo \
        vdpauinfo \
        mesa-utils \
        mesa-utils-extra \
        xdg-utils \
        dbus-x11 \
        libdbus-c++-1-0v5 \
        dmz-cursor-theme \
        numlockx \
        xcursor-themes \
        xvfb \
        xubuntu-artwork \
        xfburn \
        xfpanel-switch \
        xfce4 \
        xfdesktop4 \
        xfwm4 \
        xfce4-appfinder \
        xfce4-clipman \
        xfce4-dict \
        xfce4-goodies \
        xfce4-notes \
        xfce4-notifyd \
        xfce4-panel \
        xfce4-screenshooter \
        xfce4-session \
        xfce4-settings \
        xfce4-taskmanager \
        xfce4-terminal \
        xfce4-appmenu-plugin \
        xfce4-battery-plugin \
        xfce4-clipman-plugin \
        xfce4-cpufreq-plugin \
        xfce4-cpugraph-plugin \
        xfce4-diskperf-plugin \
        xfce4-datetime-plugin \
        xfce4-fsguard-plugin \
        xfce4-genmon-plugin \
        xfce4-indicator-plugin \
        xfce4-mpc-plugin \
        xfce4-mount-plugin \
        xfce4-netload-plugin \
        xfce4-notes-plugin \
        xfce4-places-plugin \
        xfce4-pulseaudio-plugin \
        xfce4-sensors-plugin \
        xfce4-smartbookmark-plugin \
        xfce4-statusnotifier-plugin \
        xfce4-systemload-plugin \
        xfce4-timer-plugin \
        xfce4-verve-plugin \
        xfce4-weather-plugin \
        xfce4-whiskermenu-plugin \
        xfce4-xkb-plugin && \
    cp -rf /etc/xdg/xfce4/panel/default.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml && \
    # Support libva and VA-API through NVIDIA VDPAU
    curl -fsSL -o /tmp/vdpau-va-driver.deb "https://launchpad.net/~saiarcot895/+archive/ubuntu/chromium-dev/+files/vdpau-va-driver_0.7.4-6ubuntu2~ppa1~18.04.1_amd64.deb" && apt-get install --no-install-recommends -y /tmp/vdpau-va-driver.deb && rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

# Install and configure Vulkan
RUN if [ "${UBUNTU_RELEASE}" = "18.04" ]; then apt-get update && apt-get install --no-install-recommends -y libvulkan1 vulkan-utils; else apt-get update && apt-get install --no-install-recommends -y libvulkan1 vulkan-tools; fi && \
    rm -rf /var/lib/apt/lists/* && \
    VULKAN_API_VERSION=$(dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)') && \
    mkdir -p /etc/vulkan/icd.d/ && \
    echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\": {\n\
        \"library_path\": \"libGLX_nvidia.so.0\",\n\
        \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
    }\n\
}" > /etc/vulkan/icd.d/nvidia_icd.json

# Install VirtualGL
# pinned to version 3.1
RUN VIRTUALGL_VERSION=3.1 && \
    curl -fsSL -O https://sourceforge.net/projects/virtualgl/files/virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
    curl -fsSL -O https://sourceforge.net/projects/virtualgl/files/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    apt-get update && apt-get install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_amd64.deb ./virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    rm -f virtualgl_${VIRTUALGL_VERSION}_amd64.deb virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    rm -rf /var/lib/apt/lists/* && \
    chmod u+s /usr/lib/libvglfaker.so && \
    chmod u+s /usr/lib/libdlfaker.so && \
    chmod u+s /usr/lib32/libvglfaker.so && \
    chmod u+s /usr/lib32/libdlfaker.so && \
    chmod u+s /usr/lib/i386-linux-gnu/libvglfaker.so && \
    chmod u+s /usr/lib/i386-linux-gnu/libdlfaker.so

# Create user with password ${PASSWD}
RUN apt-get update && apt-get install --no-install-recommends -y \
        sudo && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 1000 user && \
    useradd -ms /bin/bash user -u 1000 -g 1000 && \
    usermod -a -G adm,audio,cdrom,dialout,dip,fax,floppy,input,lp,lpadmin,plugdev,sudo,tape,tty,video,voice user && \
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chown user:user /home/user && \
    echo "user:${PASSWD}" | chpasswd && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone




FROM egl-base AS egl-desktop

ARG UBUNTU_RELEASE
ARG CUDA_VERSION
# Make all NVIDIA GPUs visible, but we want to manually install drivers
ARG NVIDIA_VISIBLE_DEVICES=all
ARG DEBIAN_FRONTEND=noninteractive

# Install latest selkies-gstreamer (https://github.com/selkies-project/selkies-gstreamer) build, Python application, and web application
RUN SELKIES_VERSION=1.3.7 && \
    apt-get update && apt-get install --no-install-recommends -y \
        build-essential \
        python3-pip \
        python3-dev \
        python3-gi \
        python3-setuptools \
        python3-wheel \
        tzdata \
        sudo \
        udev \
        xclip \
        x11-utils \
        xdotool \
        wmctrl \
        jq \
        gdebi-core \
        x11-xserver-utils \
        xserver-xorg-core \
        libopus0 \
        libgdk-pixbuf2.0-0 \
        libsrtp2-1 \
        libxdamage1 \
        libxml2-dev \
        libwebrtc-audio-processing1 \
        libcairo-gobject2 \
        pulseaudio \
        libpulse0 \
        libpangocairo-1.0-0 \
        libgirepository1.0-dev \
        libjpeg-dev \
        libvpx-dev \
        zlib1g-dev \
        x264 && \
    if [ "${UBUNTU_RELEASE}" \> "20.04" ]; then apt-get install --no-install-recommends -y xcvt; fi && \
    rm -rf /var/lib/apt/lists/* && \
    cd /opt && \
    curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-v${SELKIES_VERSION}-ubuntu${UBUNTU_RELEASE}.tgz" | tar -zxf - && \
    curl -O -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && pip3 install "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && rm -f "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && \
    curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-web-v${SELKIES_VERSION}.tgz" | tar -zxf - && \
    cd /usr/local/cuda/lib64 && sudo find . -maxdepth 1 -type l -name "*libnvrtc.so.*" -exec sh -c 'ln -sf $(basename {}) libnvrtc.so' \;

# Install latest noVNC web interface for fallback
RUN NOVNC_VERSION=1.4.0 && \
    apt-get update && apt-get install --no-install-recommends -y \
        autoconf \
        automake \
        autotools-dev \
        chrpath \
        debhelper \
        git \
        jq \
        python3 \
        python3-numpy \
        libc6-dev \
        libcairo2-dev \
        libjpeg-turbo8-dev \
        libssl-dev \
        libv4l-dev \
        libvncserver-dev \
        libtool-bin \
        libxdamage-dev \
        libxinerama-dev \
        libxrandr-dev \
        libxss-dev \
        libxtst-dev \
        libavahi-client-dev && \
    rm -rf /var/lib/apt/lists/* && \
    git clone "https://github.com/LibVNC/x11vnc.git" /tmp/x11vnc && \
    cd /tmp/x11vnc && autoreconf -fi && ./configure && make install && cd / && rm -rf /tmp/* && \
    curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Add index.html for noVNC that does autoconnect, autoreconnect and automatic local scaling
COPY index-novnc.html /opt/noVNC/index.html

# Add custom packages below this comment, or use FROM in a new container and replace entrypoint.sh or supervisord.conf

# can be used in derived container images to supply additional arguments to Xvfb and x11vnc
ENV XVFB_CMD_ADD=
ENV X11VNC_CMD_ADD=

COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod 755 /etc/entrypoint.sh
COPY selkies-gstreamer-entrypoint.sh /etc/selkies-gstreamer-entrypoint.sh
RUN chmod 755 /etc/selkies-gstreamer-entrypoint.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod 755 /etc/supervisord.conf

EXPOSE 8080
EXPOSE 5900

USER user
ENV USER=user
WORKDIR /home/user

CMD ["/usr/bin/supervisord"]




FROM egl-base AS egl-onlyvgl

COPY entrypoint-onlyvgl.sh /etc/entrypoint.sh
RUN chmod 755 /etc/entrypoint.sh

USER user
ENV USER=user
WORKDIR /home/user

CMD ["/etc/entrypoint.sh"]




FROM egl-base AS egl-turbovnc

ARG UBUNTU_RELEASE
ARG CUDA_VERSION
# Make all NVIDIA GPUs visible, but we want to manually install drivers
ARG NVIDIA_VISIBLE_DEVICES=all
ARG DEBIAN_FRONTEND=noninteractive

RUN TURBOVNC_VERSION=3.0.3 && \
    curl -fsSL -o "turbovnc_${TURBOVNC_VERSION}_amd64.deb" "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download" && \
    apt-get update && apt-get install -y --no-install-recommends ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
    rm -rf ./turbovnc_${TURBOVNC_VERSION}_amd64.dev && \
    rm -rf /var/lib/apt/lists/*

# Install latest noVNC web interface for fallback
RUN NOVNC_VERSION=1.4.0 && \
    apt-get update && apt-get install --no-install-recommends -y \
        autoconf \
        automake \
        autotools-dev \
        chrpath \
        debhelper \
        git \
        jq \
        python3 \
        python3-numpy \
        libc6-dev \
        libcairo2-dev \
        libjpeg-turbo8-dev \
        libssl-dev \
        libv4l-dev \
        libvncserver-dev \
        libtool-bin \
        libxdamage-dev \
        libxinerama-dev \
        libxrandr-dev \
        libxss-dev \
        libxtst-dev \
        libavahi-client-dev && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Add index.html for noVNC that does autoconnect, autoreconnect and automatic local scaling
COPY index-novnc.html /opt/noVNC/index.html

# Add custom packages below this comment, or use FROM in a new container and replace entrypoint.sh or supervisord.conf

# can be used in derived container images to supply additional arguments to Xvnc
ENV XVNC_CMD_ADD=

COPY entrypoint-turbovnc.sh /etc/entrypoint.sh
RUN chmod 755 /etc/entrypoint.sh
COPY supervisord-turbovnc.conf /etc/supervisord.conf
RUN chmod 755 /etc/supervisord.conf

EXPOSE 8080
EXPOSE 5900

USER user
ENV USER=user
WORKDIR /home/user

CMD ["/usr/bin/supervisord"]




FROM egl-base AS egl-kasmvnc

ARG UBUNTU_RELEASE
ARG CUDA_VERSION
# Make all NVIDIA GPUs visible, but we want to manually install drivers
ARG NVIDIA_VISIBLE_DEVICES=all
ARG DEBIAN_FRONTEND=noninteractive

# https://github.com/kasmtech/KasmVNC/releases/download/v1.0.1/kasmvncserver_focal_1.0.1_amd64.deb
RUN KASMVNC_VERSION=1.0.1 && \
    curl -fsSL "https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/kasmvncserver_jammy_${KASMVNC_VERSION}_amd64.deb" -o kasmvnc.deb && \
    apt-get update && apt-get install -y --no-install-recommends "./kasmvnc.deb" && \
    rm -rf kasmvnc.deb && \
    rm -rf /var/lib/apt/lists/*

# Rename KasmVNC index.html and add our own with default parameters
RUN mv /usr/share/kasmvnc/www/index.html /usr/share/kasmvnc/www/kasm.html
COPY index-kasmvnc.html /usr/share/kasmvnc/www/index.html
# Modify web files so that it does not think that it's running inside VDI and does not hide the control bar :)
RUN sed -i 's/return window.self !== window.top;/return false;/' /usr/share/kasmvnc/www/app/webutil.js
RUN sed -i 's/return window.self !== window.top;/return false;/' /usr/share/kasmvnc/www/dist/main.bundle.js

# Add custom packages below this comment, or use FROM in a new container and replace entrypoint.sh or supervisord.conf

# can be used in derived container images to supply additional arguments to Xvnc
ENV XVNC_CMD_ADD=

COPY entrypoint-kasmvnc.sh /etc/entrypoint.sh
RUN chmod 755 /etc/entrypoint.sh

EXPOSE 8443/tcp
EXPOSE 8443/udp

USER user
ENV USER=user
WORKDIR /home/user

CMD ["/etc/entrypoint.sh"]
