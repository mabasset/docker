#!/bin/bash

# Date: 6/11/2024
# Author: Matteo Bassetto
# This script creates a container to run graphical desktop applications

usage () {
	echo -e "\nUsage: $(basename $0) [OPTIONS] IMAGE"
	echo -e "\nA script to launch containerized PCA."
	echo -e "\nOptions:"
	echo -e "  -b,  --bash\tattach a bash process to the container. Use only with -d"
	echo -e "  -d,  --detach\tdetach mode: run container in the background"
	echo -e "  -h,  --help\tdisplay usage and exit"
	echo -e "  -p,  --password\tchoose container user password"
	echo -e "  -s,  --sudo\tgrant root privileges to container user"
	echo
}

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

