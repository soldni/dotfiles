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


echo "SIMLINK_SRC=${SIMLINK_SRC}"
echo "SIMLINK_DST=${SIMLINK_DST}"
mapfile -t all_files < <(find "${SIMLINK_SRC}" -mindepth 1 \
  -not -name ".DS_Store" \
  2>/dev/null)
printf "symlinking %s files...\n" "${#all_files[@]}"


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

        if [ "${relative}" = ".gitconfig" ]; then
            printf "Writing '%s':\n  include path: %s\n  dst: %s\n\n" "${relative}" "${src}" "${dst}"
            rm -rf "${dst}"
            printf "[include]\n    path = %s\n" "${src}" > "${dst}"]]
            continue
        fi

        if [ "${relative}" = ".bashrc" ] || [ "${relative}" = ".zshrc" ] || [ "${relative}" = ".bash_profile" ] || [ "${relative}" = ".profile" ]; then
            printf "Source-injecting '%s':\n  src: %s\n  dst: %s\n\n" "${relative}" "${src}" "${dst}"
            source_line="source ${src}"
            if [ -f "${dst}" ]; then
                # Remove any existing line sourcing this file
                grep -vF "${source_line}" "${dst}" > "${dst}.tmp" && mv "${dst}.tmp" "${dst}"
            fi
            # Prepend source line at the top
            printf "%s\n" "${source_line}" | cat - "${dst}" 2>/dev/null > "${dst}.tmp"
            mv "${dst}.tmp" "${dst}"
            continue
        fi

        printf "Symlinking '${relative}':\n  src: ${src}\n  dst: ${dst}\n\n"
        rm -rf "${dst}"
        ln -s "${src}" "${dst}"
    fi
done
