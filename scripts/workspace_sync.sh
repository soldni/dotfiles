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

BASE_SYNC_CMD='rsync --update --recursive --times --perms --copy-links --info=progress2 --exclude=.DS_Store --exclude=.git --rsh=ssh'

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
        echo "Usage: ${0} {-w sync_profile_1}, ..., {-w sync_profile_n}" 1>&2
        echo "       where sync_profile_n contains the following options:" 1>&2
        echo "         - src=___ source path" 1>&2
        echo "         - dst=___ destination path" 1>&2
        echo "         - noDel (optional) do not delete remote files" 1>&2
        echo "         - cmd=___ (optional) sync command" 1>&2
        echo "       option is a profile must be joined by commas (,):" 1>&2
        echo "       ${0} -w src=/path/to/src,dst=ip:/path/to/dst,noDel" 1>&2
        exit 1;
    }

    while getopts ":dw:" FLAG; do
        case "${FLAG}" in
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

    SYNC_COUNTER=0

    for WORKSPACE in "${WORKSPACES[@]}"; do
        IFS=',' read -r -a OPTIONS <<< "${WORKSPACE}"

        for OPTION in "${OPTIONS[@]}"; do
            if [[ "${OPTION}" == "src="* ]]; then
                IFS='=' read -r _IGNORE SOURCE <<< "${OPTION}"
            fi
            if [[ "${OPTION}" == "dst="* ]]; then
                IFS='=' read -r _IGNORE DESTINATION <<< "${OPTION}"
            fi
            if [[ "${OPTION}" == "cmd="* ]]; then
                IFS='=' read -r _IGNORE SYNC_CMD <<< "${OPTION}"
            fi
            if [[ "${OPTION}" == "noDel" ]]; then
                NO_DELETE_DESTINATION=1
            fi

        done

        if [ -z "${SYNC_CMD}" ]; then
          SYNC_CMD="${BASE_SYNC_CMD}"
        fi

        if [ -z $"{NO_DELETE_DESTINATION}" ] && [[ "${SYNC_CMD}" == "${BASE_SYNC_CMD}" ]]; then
            SYNC_CMD="${SYNC_CMD} --delete"
        fi

        if [ -z "${DESTINATION}" ]; then
            echo 'dst not provided!' 1>&2
            usage
        fi

        if [ -z "${SOURCE}" ]; then
            echo 'src not provided!' 1>&2
            usage
        fi

        if [[ "${SOURCE}" == *":"* ]]; then
            REMOTE_TO_LOCAL=1
        fi

        if [[ "${SYNC_CMD}" == "${BASE_SYNC_CMD}" ]]; then
            if [ -z "${REMOTE_TO_LOCAL}" ]; then
                DIR_TO_CREATE="$(dirname $(echo ${DESTINATION} | cut -d ':' -f 2))"
                DEST_HOST="$(echo ${DESTINATION} | cut -d ':' -f 1)"
                if [ -z "${DRYRUN}" ]; then
                    ssh ${DEST_HOST} "mkdir -p ${DIR_TO_CREATE}"
                else
                    echo "[DRYRUN ${SYNC_COUNTER}] CREATE ${DIR_TO_CREATE} ON ${DEST_HOST}"
                fi
            else
                # create local path if not exists
                DIR_TO_CREATE="$(diname ${DESTINATION})"
                if [ -z "${DRYRUN}" ]; then
                    mkdir -p ${DIR_TO_CREATE}
                else
                    echo "[DRYRUN ${SYNC_COUNTER}] CREATE ${DIR_TO_CREATE}"
                fi
            fi
        fi

        if [ -z "${DRYRUN}" ]; then
            if [ -z "${REMOTE_TO_LOCAL}" ]; then
                SYNC_CMD=${SYNC_CMD} _local_to_remote_workspace_sync ${SOURCE} ${DESTINATION} &
            else
                SYNC_CMD=${SYNC_CMD} _remote_to_local_workspace_sync ${SOURCE} ${DESTINATION} &
            fi
            record_pid $!
        else
            echo "[DRYRUN ${SYNC_COUNTER}] CMD: ${SYNC_CMD}"
            echo "[DRYRUN ${SYNC_COUNTER}] SRC: ${SOURCE}"
            echo "[DRYRUN ${SYNC_COUNTER}] DST:  ${DESTINATION}"
        fi

        let SYNC_COUNTER++

    done

    sleep 1

    if [ -z "${DRYRUN}" ]; then
        trap terminate_all SIGINT
        trap terminate_all SIGTERM

        echo "Starting... press CTRL-C to terminate sync."

        while true; do
            sleep 60
        done
    fi
}

workspaces_sync "${@}"
