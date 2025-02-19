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


if [ -z "${SIMLINK_SRC}" ]; then
    SIMLINK_SRC="${SCRIPT_DIR}/home-symlink"
fi

if [ -z "${SIMLINK_DST}" ]; then
    SIMLINK_DST="${HOME}"
fi

all_files=( )
IFS=$'\n' eval 'for i in `find ${SIMLINK_SRC}/.* ${SIMLINK_SRC}/* -name "*" -not -name ".DS_Store" -not -name "." -not -name ".." 2>/dev/null`; do all_files+=( "$i" ); done'

for ((i = 0; i < ${#all_files[@]}; i++)) do
    if [ -f "${all_files[i]}" ]; then
        relative=$(echo "${all_files[i]}" | sed "s|${SIMLINK_SRC}/||g")
        relative_dir=$(dirname "${relative}")

      src="${SIMLINK_SRC}/${relative}"
      dst="${SIMLINK_DST}/${relative}"

      if [ "${relative_dir}" != '.' ]; then
            dest_rel_dir="${SIMLINK_DST}/${relative_dir}"

            if [ ! -d "${dest_rel_dir}" ]; then
                rm -rf "${dest_rel_dir}"
            fi
            mkdir -p "${SIMLINK_DST}/${relative_dir}"
      fi
      printf "Symlinking '${relative}':\n  src: ${src}\n  dst: ${dst}\n\n"
      rm -rf "${dst}"
      ln -s "${src}" "${dst}"
    fi
done
