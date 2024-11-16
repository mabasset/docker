#!/bin/bash

# Date: 15/10/2024
# Author: Matteo Bassetto
# This script installs docker in a ubuntu distro (tested from 18.04 to 24.04)

usage () {
	echo -e "\nUsage: sudo $(basename $0) [OPTIONS]"
	echo -e "\nA script to set up docker."
	echo -e "\nOptions:"
	echo -e "  -c,  --cleaner\tinstall docker-clean.sh"
	echo -e "  -h,  --help\t\tdisplay usage and exit"
	echo -e "  -n,  --no-install\tprevent docker installation"
	echo -e "  -r,  --reboot\t\treboot system"
	echo -e "  -u,  --user string\tadd user to docker group"
	echo
}

abort () {
	echo "see $(basename $0) --help" >&2
	exit 1
}

root-check () {
	if [ $(id -u) -ne 0 ]
	then
		echo "$(basename $0): root privileges are required." >&2
		abort
	fi
}

user-check () {
	[ ! $(id "$1") ] && abort
}

docker-install () {
	apt-get update
	apt-get install -qqy ca-certificates curl
	install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	chmod a+r /etc/apt/keyrings/docker.asc
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
		$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
		tee /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install -qqy docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

cleaner-install () {
	SRC="https://raw.githubusercontent.com/mabasset/docker/refs/heads/main/docker-clean.sh"
	DST="/usr/local/bin/docker-clean"
	wget -O "$DST" "$SRC" &> /dev/null
	chmod 755 "$DST"
}

group-add () {
	groupadd "$1" &> /dev/null
	usermod -aG "$1" "$2"
	if [ $? -eq 0 ]
	then
		echo "$(basename $0): $2 added to $1 group."
		echo "$(basename $0): $2's group membership requires a re-evaluation."
	fi
}

reboot-delayed () {
	echo "$(basename $0): rebooting the system... ($1 sec)"
	sleep "$1"
	reboot
}

# parse script's arguments
# -- is used to signify the end of command options
LONGOPTS="cleaner,help,no-install,reboot,user:"
OPTIONS="c,h,n,r,u:"
# getopt checks args validity and returns a formatted string
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name $(basename $0) -- "$@") ||
	abort
# eval removes special chars like " or ' and executes set command to copy the formatted string inside $@
eval set -- "$PARSED"

# set up flags based on script's options
CLEANER=
INSTALL=1
REBOOT=
USR=
while [ "$1" != "--" ]
do
	case "$1" in
		-c|--cleaner)
			CLEANER=1;;
		-h|--help)
			usage
			exit 0;;
		-n|--no-install)
			INSTALL=;;
		-r|--reboot)
			REBOOT=1;;
		-u|--user)
			USR="$2"
			shift;;
		*)
			exit 1;;
	esac
	shift
done
shift

# check for arguments after options
if [ "$#" -ne 0 ]
then
	echo "'$(basename $0)' accepts no arguments." >&2
	abort
fi

# installation requires root privileges
root-check

# user must be valid
[ ! -z "$1" ] && user-check "$USR"

# enable docker rootless mode for a specific user
[ ! -z "$USR" ] && group-add "doker" "$USR"

# quit if any command exits with a non-zero status
set -e

# start docker installation
[ ! -z "$INSTALL" ] && docker-install

# install dokcer data cleaner
[ ! -z "$CLEANER" ] && cleaner-install

# reboot system for group re-evaluation
DELAY=5
[ ! -z "$REBOOT" ] && reboot-delayed $DELAY


#container-toolkit
#curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
# && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
# 	sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
# 	tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
#sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
#apt-get update
#apt-get install -y nvidia-container-toolkit
#nvidia-ctk runtime configure --runtime=docker
#systemctl restart docker
#nvidia-ctk runtime configure --runtime=docker --config=$HOME/.config/docker/daemon.json
#systemctl restart docker
#nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place
#docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
