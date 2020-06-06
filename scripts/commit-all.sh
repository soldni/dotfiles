#!/bin/bash

USAGE="commit-all.sh -k [/path/to/ssh/key] -g [/path/to/git/dir]"

# parse input options
while getopts "k:g:" opt; do
    case ${opt} in
        k )
            SSH_KEY=$OPTARG
            ;;
        g )
            GIT_PATH=$OPTARG
            ;;
        h )
            echo -e "${USAGE}"
            exit
            ;;
        \? )
            echo "USAGE: ${USAGE}" 1>&2
            echo "ERROR: invalid option: '-$OPTARG'" 1>&2
            exit 1
          ;;
        : )
            echo "USAGE: ${USAGE}" 1>&2
            echo "Invalid option: '-$OPTARG' requires an argument" 1>&2
            exit 1
          ;;
      esac
done


# check if option were provided for input
if [ -z "${SSH_KEY}" ]; then
    echo "ERROR: SSH_KEY not specified!" 1>&2
    echo "USAGE: ${USAGE}" 1>&2
    exit 1
fi
if [ -z "${GIT_PATH}" ]; then
    echo "ERROR: GIT_PATH not specified!" 1>&2
    echo "USAGE: ${USAGE}" 1>&2
    exit 1
fi

# memorize current folder, go to right folder
CURRENT_DIR=`pwd`
cd $GIT_PATH

# do the git thing
git add -A
git commit -am "$(date)"
GIT_SSH_COMMAND="ssh -i ${SSH_KEY}" git push

# return to previous dir
cd $CURRENT_DIR
