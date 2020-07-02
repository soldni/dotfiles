#! /usr/bin/env bash

if [ -z "${@}" ]; then
    printf "Usage: vnc_over_ssh.sh [ssh options]\n" > /dev/stderr
    exit 1
fi

ssh -NL 5900:localhost:5900 "${@}" &
TUNNEL_PID=$!

printf "Connecting in "

for i in 3 2 1; do
    printf "${i}..."
    sleep 1
done

printf "0\n"

open "vnc://127.0.0.1:5900"

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    kill $TUNNEL_PID
    printf "\nCTRL-C pressed. Bye!\n"
    exit
}

while true; do
    sleep 360
done