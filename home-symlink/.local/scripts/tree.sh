#!/usr/bin/env bash

FILTER_AND_STYLE=$(cat <<END
# python script starts here

import sys, errno, os

depth=0
div=2

try:
    for ln in sys.stdin:
        ln=ln.strip()
        if not ln or ln.endswith('/') or ln == '.:':
            continue

        if ln.endswith(':'):
            # directory
            extra, name = ln.strip(':').rsplit('/', 1)
            depth = (1 + extra.count('/')) * div
            print('  |{} {}/'.format('-' * depth, name))
        else:
            print('  |{}> {}'.format('-' * (depth + div), ln))
except IOError as e:
    if e.errno == errno.EPIPE:
        pass

# script ends here
END
)


if [[ ! -z "${1}" ]] && [[ "${1}" != "-f" ]]; then
    DIR=${1}
elif [[ ! -z "${2}" ]] && [[ "${2}" != "-f" ]]; then
    DIR="${2}"
else
    DIR='.'
fi

# print current dir
echo "${DIR}"

if [ "${2}" == "-f" ] || [ "${1}" == "-f" ]; then
    LIST_FILES=1
fi

if [ -z "${LIST_FILES}" ]; then
    # | grep -v "${DIR}:"
    ls -R --color=no "${DIR}" | grep -P ":$"  | sed -e "s/:$//" -e "s/[^/]*[/]/--/g" -e "s/^/ |/" -e "s/\(-\)\([^-]\)/\1 \2/" -e '1d'
    # ls -R | grep "^[.]/" | sed -e "s/:$//" -e "s/[^\/]*\//--/g" -e "s/^/   |/"
    # grep:    select folders (filter out files)
    # 1st sed: remove trailing colon
    # 2nd sed: replace higher level folder names with dashes
    # 3rd sed: indent graph and add leading vertical bar
    # 4th sed: add a space at the end
    # 5th sed: throw away first line (current directory)
    topFolders=$(ls -F -1 | grep "/" | wc -l)
    test $topFolders -ne 0 || echo "   --> no subfolders"
else
    ls -1Rp --color=no "${DIR}" | python -c "${FILTER_AND_STYLE}"
fi
