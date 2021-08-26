#!/usr/bin/env bash

# Function to sync local workspaces to remove workspaces

# How to use it:
# 1. install fswatch: https://github.com/emcrisostomo/fswatch
# 2. open tmux or screen
# 3. run the script as follows
#       bash workspace_sync.sh  \
#           -w "/first/local/path/to/sync,remote_machine:/first/remote/path/to/sync_to" \
#           -w "/second/local/path/to/sync,another_remote_machine:/second/remote/path/to/sync_to" \
#           ...
#    as you can see, you can sync multiple folders to multiple
#    machines at the same time. Syncs are triggered every time
#    you save a file in any local directory.

function _local_to_remote_workspace_sync() {
    LOCAL_WORKSPACE=${1}
    REMOTE_WORKSPACE=${2}

    echo "[$(date)] Initial sync of '${LOCAL_WORKSPACE}' to '${REMOTE_WORKSPACE}'..."
    $SYNC_CMD $LOCAL_WORKSPACE $REMOTE_WORKSPACE

    fswatch -or "${LOCAL_WORKSPACE}" |  while read f; do
        echo "[$(date)] Syncing '${LOCAL_WORKSPACE}' to '${REMOTE_WORKSPACE}'..."
        $SYNC_CMD $LOCAL_WORKSPACE $REMOTE_WORKSPACE
    done
}

function _remote_to_local_workspace_sync() {
    REMOTE_WORKSPACE=${1}
    LOCAL_WORKSPACE=${2}

    while true; do
        echo "[$(date)] Syncing '${REMOTE_WORKSPACE}' to '${LOCAL_WORKSPACE}'..."
        $SYNC_CMD $REMOTE_WORKSPACE $LOCAL_WORKSPACE

        # 30 secs timeout
        sleep 30;
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

        if [[ "${LOCAL}" == *":"* ]]; then
            REMOTE_TO_LOCAL=1
        fi

        if [ -z "${DRYRUN}" ]; then
            if [ -z "${REMOTE_TO_LOCAL}" ]; then
                SRC_DIR=${LOCAL}
                DST_DIR=${REMOTE}
                SYNC_CMD=${SYNC_CMD} _local_to_remote_workspace_sync ${LOCAL} ${REMOTE} &
            else
                SRC_DIR=${REMOTE}
                DST_DIR=${LOCAL}
                SYNC_CMD=${SYNC_CMD} _remote_to_local_workspace_sync ${REMOTE} ${LOCAL} &
            fi
            record_pid $!
        else
            echo "DRYRUN: "
            echo "  CMD:  ${SYNC_CMD}"
            echo "  SRC:  ${SRC_DIR}"
            echo "  DST:  ${DST_DIR}"
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
