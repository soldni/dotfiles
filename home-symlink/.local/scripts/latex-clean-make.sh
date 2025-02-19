#!/usr/bin/env bash

set -e

TEX_PATH="${1}"
TEX_FILENAME="$(basename ${TEX_PATH})"

if [ "$(basename ${TEX_FILENAME} .tex)" == "${TEX_FILENAME}" ]; then
    echo "ERROR: '${TEX_FILENAME}' does not have the right extension." 1>&2
    exit 1
fi

TEX_DIRECTORY="$(dirname $TEX_PATH)"

if [ ! -d "${TEX_DIRECTORY}" ]; then
    echo "ERROR: directory of '${TEX_FILENAME}' not found." 1>&2
    exit 1
fi

latex-clean.py $TEX_DIRECTORY
latex-make.sh "$@"
