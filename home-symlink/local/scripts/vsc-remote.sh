#!/usr/bin/env bash

# This script opens Visual Studio Code on a remote host using the Remote - SSH extension.
# useful for quickly copying IP in terminal and opening in vscode

HAS_VSCODE_CLI=$(command -v code)

if [ -z "$HAS_VSCODE_CLI" ]; then
  echo "Visual Studio Code CLI not found. Please install it."
  exit 1
fi

REMOTE_HOST=$1

if [ -z "$REMOTE_HOST" ]; then
  echo "Usage: vsc-remote.sh <remote-host> [remote-path]"
  exit 1
fi

REMOTE_PATH=$2

function get_remote_path() {
  local remote_path=$(ssh ${REMOTE_HOST} -- 'pwd' 2>/dev/null)
  if [ -z "$remote_path" ]; then
    echo "Failed to get remote path. Make sure you can SSH into the remote host." >&2
    exit 1
  fi
  echo "$remote_path"
}

if [ -z "$REMOTE_PATH" ]; then
  REMOTE_PATH=$(get_remote_path)
elif [[ ! "$REMOTE_PATH" =~ ^/ ]]; then
  REMOTE_PATH=$(get_remote_path)/${REMOTE_PATH}
fi

echo "Opening Visual Studio Code on remote host ${REMOTE_HOST} at ${REMOTE_PATH}..."

code --remote ssh-remote+${REMOTE_HOST} ${REMOTE_PATH}
