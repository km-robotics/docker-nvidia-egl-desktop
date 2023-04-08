#!/bin/bash -e

export PATH="${PATH}:/opt/VirtualGL/bin"


sudo chown user:user /home/user
echo "user:${PASSWD:-*}" | sudo chpasswd
sudo rm -rf /tmp/.X*
sudo ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" | sudo tee /etc/timezone > /dev/null

# create self signed cert
mkdir -p /home/user/.vnc
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $HOME/.vnc/self.pem -out $HOME/.vnc/self.pem -subj "/C=US/ST=VA/L=None/O=None/OU=DoFu/CN=kasm/emailAddress=none@none.none"
# kasmvnc (at least 1.0.1) wants snakeoil key, which is not accessible for an ordinary user
# configuring with `vncserver -cert ... -key ...` does not work, probably the web part of kasmvnc uses only the config file
# so we will write a minimal config file to default location
cat - > /home/user/.vnc/kasmvnc.yaml << EOF
network:
  ssl:
    pem_certificate: /home/user/.vnc/self.pem
    pem_key: /home/user/.vnc/self.pem
    require_ssl: true
EOF

mkdir -p /tmp/xdg_runtime_dir
export XDG_RUNTIME_DIR=/tmp/xdg_runtime_dir

# emulate dbus for xfce4
# https://georgik.rocks/how-to-start-d-bus-in-docker-container/
sudo bash -c 'dbus-uuidgen > /var/lib/dbus/machine-id'
sudo mkdir -p /var/run/dbus
#sudo dbus-daemon --config-file /usr/share/dbus-1/system.conf --print-address
sudo /etc/init.d/dbus start

# remove pulseaudio panel, maybe do it before xfce4 starts?
# see https://forum.xfce.org/viewtopic.php?id=8619

export DISPLAY=":0"
export __GL_SYNC_TO_VBLANK="0"
export __NV_PRIME_RENDER_OFFLOAD="1"

if [ -n "${BASIC_AUTH_PASSWORD:-$PASSWD}" ]; then
  # password specified
  # set specified password for websocket and HTTP connection via kasmvncpasswd tool
  # owner+write permissions
  echo -e "${BASIC_AUTH_PASSWORD:-$PASSWD}\n${BASIC_AUTH_PASSWORD:-$PASSWD}\n" | kasmvncpasswd -u user -o -w
  export VNC_PASSWORDARG=""
else
  # no password
  # we must set at least some password with kasmpasswd (tool that sets password for websocket and HTTP connection) even if it won't be used ...
  # owner+write permissions
  echo -e "placeholder\nplaceholder\n" | kasmvncpasswd -u user -o -w
  export VNC_PASSWORDARG="-disableBasicAuth"
fi
set -x
vncserver ${DISPLAY} \
  -select-de XFCE \
  -geometry "${SIZEW}x${SIZEH}" \
  -depth ${CDEPTH} \
  ${VNC_PASSWORDARG} \
  -alwaysshared \
  -noxstartup \
  -maxclients 128 \
  -noreset \
  r \
  -to 5 -rfbwait 8000 \
  -listen tcp -ac \
  ${X11VNC_CMD_ADD} ${XVNC_CMD_ADD}
set +x


# Wait for X11 to start
echo "Waiting for X socket"
until [ -S "/tmp/.X11-unix/X${DISPLAY/:/}" ]; do sleep 1; done
echo "X socket is ready"


# Add custom processes below this section, or within `supervisord.conf` to perform service management like systemd
if [ -n "$(nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)" ]; then
  export VGL_DISPLAY="${VGL_DISPLAY:-egl}"
  export VGL_REFRESHRATE="$REFRESH"
  vglrun +wm xfce4-session &
else
  xfce4-session &
fi

# https://askubuntu.com/questions/950252/x11vnc-headless-on-ubuntu-is-very-slow-until-monitor-connected
sleep 2
xfconf-query -c xfwm4 -p /general/vblank_mode --create -s off
xfconf-query -c xfwm4 -p /general/use_compositing -s false
# to be sure, do it twice
sleep 2
xfconf-query -c xfwm4 -p /general/vblank_mode --create -s off
xfconf-query -c xfwm4 -p /general/use_compositing -s false


echo "Session Running. Press [Return] to exit."
read
