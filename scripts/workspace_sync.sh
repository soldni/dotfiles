#!/usr/bin/env bash

# Function to sync local workspaces to remove workspaces


function _workspace_sync() {
    LOCAL_WORKSPACE=${1}
    REMOTE_WORKSPACE=${2}

    echo "[$(date)] Initial sync of '${LOCAL_WORKSPACE}' to '${REMOTE_WORKSPACE}'..."
    $SYNC_CMD $LOCAL_WORKSPACE $REMOTE_WORKSPACE

    fswatch -or "${LOCAL_WORKSPACE}" |  while read f; do
        echo "[$(date)] Syncing '${LOCAL_WORKSPACE}' to '${REMOTE_WORKSPACE}'..."
        $SYNC_CMD $LOCAL_WORKSPACE $REMOTE_WORKSPACE
    done
}


function workspaces_sync() {
    function usage() {
        echo "Usage: ${0} {-w src1,dest1}, ..., {-w srcN,destN}" 1>&2; exit 1;
    }

    while getopts ":d:w:" option; do
        case "${option}" in
            w)
                WORKSPACES+=("${OPTARG}");;
            d)
                DRYRUN=1;;
            *)
                usage;;
        esac
    done
    shift $((OPTIND-1))

    if [ -z "${CONFIG}" ]; then
        CONFIG="${HOME}/.config/workspace_sync"
    fi
    mkdir -p "$(dirname ${CONFIG})"

    function record_pid() {
        echo ${1} >> "${CONFIG}"
    }

    function terminate_all() {
        PIDS=()
        while IFS= read -r line; do
            PIDS+=("$line")
        done < ${CONFIG}

        for PID in "${PIDS[@]}"; do
            kill -9 $PID && TERMINATED+="${PID},"
        done
        TERMINATED=$(echo ${TERMINATED} | sed 's/,*$//g')
        echo "Terminated ${TERMINATED}"

        rm ${CONFIG}
        exit
    }

    for WORKSPACE in "${WORKSPACES[@]}"; do
        IFS=',' read -r LOCAL REMOTE SYNC_CMD <<< "${WORKSPACE}"

        if [ -z "${SYNC_CMD}" ]; then
            SYNC_CMD='rsync --update --recursive --times --perms --copy-links --delete --info=progress2 --exclude=.DS_Store --exclude=.git --rsh=ssh'
        fi

        if [ -z "${REMOTE}" ]; then
            echo 'LOCAL or REMOTE not provided!' 1>&2
            usage
        fi

        if [ -z "${DRYRUN}" ]; then
            SYNC_CMD=${SYNC_CMD} _workspace_sync ${LOCAL} ${REMOTE} &
            record_pid $!
        else
            echo "DRYRUN: "
            echo "${SYNC_CMD}"
            echo "${LOCAL}"
            echo "${REMOTE}"
            echo
        fi

    done

    trap terminate_all SIGINT
    trap terminate_all SIGTERM

    echo "Starting... press CTRL-C to terminate sync."

    while true; do
        sleep 60
    done
}

workspaces_sync "${@}"
