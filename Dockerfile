FROM		ubuntu:18.04

RUN			apt update \
			&& apt upgrade -qqy \
			&& apt install -qqy \
				vlc \
				mpv \
				vim \
				x11-apps

ENTRYPOINT	[ "/bin/bash", "-c" ]
CMD			[ "tail -f /dev/null" ]
