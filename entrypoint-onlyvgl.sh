#!/bin/bash -e

sudo chown user:user /home/user
echo "user:${PASSWD:-*}" | sudo chpasswd
sudo ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" | sudo tee /etc/timezone > /dev/null
export PATH="${PATH}:/opt/VirtualGL/bin"

export __GL_SYNC_TO_VBLANK="0"
export __NV_PRIME_RENDER_OFFLOAD="1"

# Add custom processes below this section, or within `supervisord.conf` to perform service management like systemd
if [ -n "$(nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)" ]; then
  export VGL_DISPLAY="${VGL_DISPLAY:-egl}"
  export VGL_REFRESHRATE="$REFRESH"
  vglrun +wm $@
else
  $@
fi
