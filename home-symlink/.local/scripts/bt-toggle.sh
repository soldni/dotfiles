#!/usr/bin/env bash

SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"
USAGE="usage: -e to enable, -d to disable, -t to toggle; mutually exclusive."


function interrupt () {
    msg=${1}
    if [ ! -z "${msg}" ]; then
        echo "${SCRIPT_NAME}: ${msg}"  > /dev/stderr
    fi
    exit 1
}


while getopts "htde" arg; do
    case $arg in
        t)
            if [ ! -z "${ACTION}" ]; then
                interrupt "Options are mutually exclusive!"
            fi
            ACTION="?"
            ;;
        e)
            if [ ! -z "${ACTION}" ]; then
                interrupt "Options are mutually exclusive!"
            fi
            ACTION=1
            ;;
        d)
            if [ ! -z "${ACTION}" ]; then
                interrupt "Options are mutually exclusive!"
            fi
            ACTION=0
            ;;
        h)
            interrupt "${USAGE}"
            ;;
        *)
            interrupt "${USAGE}"
            ;;
  esac
done

if [ ! -f "/opt/homebrew/bin/blueutil" ]; then
	interrupt "Please install 'blueutil' with brew"
fi

if [ -z "${ACTION}" ]; then
    interrupt "No option provided; ${USAGE}"
elif [ "${ACTION}" == "?" ]; then
    bt_is_on="$(/opt/homebrew/bin/blueutil | grep 'Power: 1')"
    if [ -z "${bt_is_on}" ]; then
        ACTION=1
    else
        ACTION=0
    fi
fi

if [ "${ACTION}" == "1" ]; then
    # Turn bluetooth on
    /opt/homebrew/bin/blueutil -p 1

    # Restart Sidecar
    /bin/launchctl kickstart -k "gui/$(id -u)/com.apple.sidecar-relay"
    /bin/launchctl kickstart -k "gui/$(id -u)/com.apple.sidecar-display-agent"

    # Restart Universal Control
    /bin/launchctl kickstart -k "gui/$(id -u)/com.apple.ensemble"

	echo "Bluetooth is now on"
else
    # Turn bluetooth off
    /opt/homebrew/bin/blueutil -p 1
	echo "Bluetooth is now off"
fi
