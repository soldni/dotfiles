#!/usr/bin/env bash

TEX_PATH="${1}"
TEX_FILENAME="$(basename ${TEX_PATH})"

if [ "$(basename ${TEX_FILENAME} .tex)" == "${TEX_FILENAME}" ]; then
    echo "ERROR: '${TEX_FILENAME}' does not have the right extension."
    exit 1
fi

TEX_DIRECTORY="$(dirname $TEX_PATH)"

if [ ! -d "${TEX_DIRECTORY}" ]; then
    echo "ERROR: directory of '${TEX_FILENAME}' not found."  1>&2
    exit 1
fi

AUX_FILENAME="$(basename $TEX_FILENAME .tex).aux"


REFTOOL="${2}"

if [ -z $REFTOOL ]; then
    REFTOOL="bibtex"
fi

HAS_REFTOOL="$(which ${REFTOOL} 2>/dev/null)"

if [ -z "${HAS_REFTOOL}" ]; then
    echo "ERROR: reference tool \"${REFTOOL}\" not found." 1>&2
    exit 1
fi

if [ "${REFTOOL}" == "biber" ]; then
    AUX_FILENAME="$(basename $AUX_FILENAME .aux)"
fi

# will halt if error occurs
set -e

#compile!
pdflatex --halt-on-error --interaction=nonstopmode $TEX_FILENAME
$REFTOOL $AUX_FILENAME
pdflatex --halt-on-error --interaction=nonstopmode $TEX_FILENAME

# bibtex requires another pass
if [ "${REFTOOL}" == "bibtex" ]; then
    pdflatex --halt-on-error --interaction=nonstopmode $TEX_FILENAME
fi

echo "done compiling."
