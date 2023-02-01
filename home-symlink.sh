#! /usr/bin/env	bash

# set -x

# get script directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    # if $SOURCE was a relative symlink, we need to resolve it
    # relative to the path where the symlink file was located
    [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"


SIMLINK_SRC=$1
SIMLINK_DST=$2
USE_HIDDEN=$3

if [ -z "${SIMLINK_SRC}" ]; then
    SIMLINK_SRC="${SCRIPT_DIR}/home-symlink"
fi

if [ -z "${SIMLINK_DST}" ]; then
    SIMLINK_DST="${HOME}"
fi

if [ -z "${USE_HIDDEN}" ]; then
    USE_HIDDEN=1
fi

all_files=( )
IFS=$'\n' eval 'for i in `find ${SIMLINK_SRC}/* -name "*" -not -name ".DS_Store"`; do all_files+=( "$i" ); done'

for ((i = 0; i < ${#all_files[@]}; i++)) do
    if [ -f "${all_files[i]}" ]; then
        relative=$(echo "${all_files[i]}" | sed "s|${SIMLINK_SRC}/||g")
        relative_dir=$(dirname "${relative}")

        if [ "${USE_HIDDEN}" == 1 ]; then
            hidden_prefix=''
        fi

      src="${SIMLINK_SRC}/${relative}"
      dst="${SIMLINK_DST}/${hidden_prefix}${relative}"

      if [ "${relative_dir}" != '.' ]; then
            dest_rel_dir="${SIMLINK_DST}/${hidden_prefix}${relative_dir}"

            if [ ! -d "${dest_rel_dir}" ]; then
                rm -rf "${dest_rel_dir}"
            fi
            mkdir -p "${SIMLINK_DST}/${hidden_prefix}${relative_dir}"
      fi
      printf "Symlinking '${relative}':\n  src: ${src}\n  dst: ${dst}\n\n"
      rm -rf "${dst}"
      ln -s "${src}" "${dst}"
    fi
done
