#!/bin/bash

# Date: 6/11/2024
# Author: Matteo Bassetto
# This script creates a container to run graphical desktop applications

usage () {
	echo -e "\nUsage: $(basename $0) [OPTIONS] NAME"
	echo -e "\nA script to launch containerized GUI."
	echo -e "\nOptions:"
	echo -e "  -h,  --help\tdisplay usage and exit"
	echo
}

abort () {
	echo "see $(basename $0) --help" >&2
	exit 1
}

root-check () {
	if [ $(id -u) -eq 0 ]
	then
		echo "$(basename $0): running as root is not allowed." >&2
		abort
	fi
}

# parse script's arguments
# -- is used to signify the end of command options
LONGOPTS="help"
OPTIONS="h"
# getopt checks args validity and returns a formatted string
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name $(basename $0) -- "$@") ||
	abort
# eval removes special chars like " or ' and executes set command to copy the formatted string inside $@
eval set -- "$PARSED"

# set up flags based on script's options
while [ "$1" != "--" ]
do
	case "$1" in
		-h|--help)
			usage
			exit 0;;
		*)
			exit 1;;
	esac
	shift
done
shift

# check for root
root-check

# check for arguments after options
if [ "$#" -ne 1 ]
then
	echo "'$(basename $0)': wrong argument number" >&2
	abort
fi

NAME="$1"

docker build -t "$NAME" .

docker run \
  --name "${NAME}" \
  --network host \
  --user "$(id -u):$(id -g)" \
  --env DISPLAY="${DISPLAY}" \
  --env XDG_RUNTIME_DIR="/run/user/${UID}" \
  --env PULSE_SERVER="/run/user/${UID}/pulse/native" \
  --env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${UID}/bus" \
  --volume /etc/localtime:/etc/localtime:ro \
  --volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
  --volume /run/user/${UID}/:/run/user/${UID}/ \
  --device /dev/dri \
  --device /dev/snd \
  --security-opt apparmor=unconfined \
  "${NAME}"

