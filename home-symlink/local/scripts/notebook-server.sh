#!/bin/bash

set -e

USAGE="USAGE: notebook-server.sh [start|stop]"
PID_LOCATION="${HOME}/.jupyter/pid.txt"

if [ -z "$1" ]
then
    echo $USAGE
    exit 1
fi

has_jupyter_lab=`which jupyter-lab 2>/dev/null`

if [[ ! -z $has_jupyter_lab ]]
then
    start='jupyter-lab'
else
    start='jupyter-notebook'
fi


clean_pid=`ps -ef | grep jupyter | wc -l`
if [ "$clean_pid" -eq "1" ]; then
    rm -rf $PID_LOCATION
fi

if [ "$1" == "start" ]
then
    if [ -f $PID_LOCATION ]
    then
        echo "Server already running"
        exit
    fi

    CMD="${start} --notebook-dir=$HOME/jupyter-notebook --certfile=$HOME/.jupyter/keys/mycert.pem --keyfile=$HOME/.jupyter/keys/mykey.key --no-browser --port=2622 --ip='*'"
    nohup ${CMD} > /dev/null 2>&1 &echo $! > "$HOME/.jupyter/pid.txt"
    echo "Server started"
elif [ "$1" == "stop" ]
then
    kill -15 `cat $HOME/.jupyter/pid.txt`
    rm -rf $HOME/.jupyter/pid.txt
    echo "Server stopped"
else
    echo $USAGE
    exit 1
fi
