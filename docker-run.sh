#!/bin/bash

# Date: 6/11/2024
# Author: Matteo Bassetto
# This script containerizes an application

docker build -t vlc .

NAME="vlc"

docker run -d \
  --name "${NAME}" \
  --network host \
  --user "${UID}:$(id -g)" \
  --env DISPLAY="${DISPLAY}" \
  --env XDG_RUNTIME_DIR="/run/user/${UID}" \
  --env PULSE_SERVER="/run/user/${UID}/pulse/native" \
  --env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${UID}/bus" \
  --volume /etc/localtime:/etc/localtime:ro \
  --volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
  --volume /run/user/${UID}/:/run/user/${UID}/ \
  --volume "$(pwd)/shared/:/shared/" \
  --device /dev/dri \
  --device /dev/snd \
  --security-opt apparmor=unconfined \
  "${NAME}"

