#!/bin/bash -e

trap "echo TRAPed signal" HUP INT QUIT KILL TERM

export PATH="${PATH}:/opt/VirtualGL/bin"
export PATH="${PATH}:/opt/TurboVNC/bin"


sudo chown user:user /home/user
echo "user:${PASSWD:-*}" | sudo chpasswd
sudo rm -rf /tmp/.X*
sudo ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" | sudo tee /etc/timezone > /dev/null

mkdir -p /tmp/xdg_runtime_dir
export XDG_RUNTIME_DIR=/tmp/xdg_runtime_dir


sudo /etc/init.d/dbus start

export DISPLAY=":0"
export __GL_SYNC_TO_VBLANK="0"
export __NV_PRIME_RENDER_OFFLOAD="1"

if [ -n "${BASIC_AUTH_PASSWORD:-$PASSWD}" ]; then
  mkdir -p /home/user/.vnc
  echo "${BASIC_AUTH_PASSWORD:-$PASSWD}" | vncpasswd -f > /home/user/.vnc/passwd
  sudo chown -R user:user /home/user/.vnc
  sudo chmod u=rw,go= /home/user/.vnc/passwd
  export VNC_PASSWORDARG="-securitytypes Vnc -rfbauth /home/user/.vnc/passwd"
else
  export VNC_PASSWORDARG="-securitytypes None"
fi
set -x
vncserver ${DISPLAY} \
  -geometry "${SIZEW}x${SIZEH}" \
  -depth ${CDEPTH} \
  ${VNC_PASSWORDARG} \
  -noautokill \
  -alwaysshared \
  -vgl \
  -noxstartup \
  -maxclients 128 \
  -noreset \
  r \
  -to 5 -rfbwait 8000 \
  -listen tcp -ac \
  ${X11VNC_CMD_ADD}
set +x

if [ "${NOVNC_ENABLE,,}" = "true" ]; then
  /opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 --heartbeat 10 &
fi


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
sleep 10
xfconf-query -c xfwm4 -p /general/vblank_mode --create -s off
xfconf-query -c xfwm4 -p /general/use_compositing -s false


echo "Session Running. Press [Return] to exit."
read
