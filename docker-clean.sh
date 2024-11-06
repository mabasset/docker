#!/bin/bash

# Date: 15/10/2024
# Author: Matteo Bassetto
# This script removes Docker data from the system

usage () {
	echo -e "\nUsage: $(basename $0) [OPTIONS]"
	echo -e "\nA script to delete all docker containers."
	echo -e "\nOptions:"
	echo -e "  -a,  --all\t\tremove all data"
	echo -e "  -c,  --cache\t\tremove unused build cache"
	echo -e "  -h,  --help\t\tdisplay usage and exit"
	echo -e "  -i,  --images\t\tremove all images"
	echo -e "  -n,  --network\tremove all networks"
	echo -e "  -v,  --volumes\tremove all volumes"
	echo
}

abort () {
	echo "see $(basename $0) --help" >&2
	exit 1
}

delete-containers () {
	echo -e "\nCONTAINERS:"
	docker rm -f $(docker ps -qa) 2> /dev/null
	[ $? -ne 0 ] && echo "none"
}

delete-volumes () {
	echo -e "\nVOLUMES:"
	docker volume rm -f $(docker volume ls -q) 2> /dev/null
	[ $? -ne 0 ] && echo "none"
}

delete-images () {
	echo -e "\nIMAGES:"
	docker image rm -f $(docker image ls -q) 2> /dev/null
	[ $? -ne 0 ] && echo "none"
}

delete-networks () {
	echo -e "\nNETWORKS:"
	docker network rm $(docker network ls -q -f "type=custom") 2> /dev/null
	[ $? -ne 0 ] && echo "none"
}

delete-cache () {
	echo -e "\nCACHE:"
	docker builder prune -f 2> /dev/null
}

# parse script's arguments
# -- is used to signify the end of command options
LONGOPTS="all,cache,help,images,network,volumes"
OPTIONS="achinv"
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name $(basename $0) -- "$@") ||
	abort
# eval removes special chars like " or ' and executes set command to copy the formatted string inside $@
eval set -- "$PARSED"

# set up flags based on script's options
CACHE=
IMG=
NET=
VLM=
while [ $1 != "--" ]
do
	case "$1" in
		-a|--all)
			CACHE=1
			IMG=1
			NET=1
			VLM=1;;
		-c|--cache)
			CACHE=1;;
		-h|--help)
			usage
			exit 0;;
		-i|--images)
			IMG=1;;
		-n|--network)
			NET=1;;
		-v|--volumes)
			VLM=1;;
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

delete-containers

[ ! -z "$VLM" ] && delete-volumes

[ ! -z "$IMG" ] && delete-images

[ ! -z "$NET" ] && delete-networks

[ ! -z "$CACHE" ] && delete-cache

echo