#! /usr/bin/env	bash

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

to_symlink_dir="${SCRIPT_DIR}/home-symlink"
for f in $(find ${to_symlink_dir}/* -name '*' -not -name ".DS_Store"); do
   if [ -f "${f}" ]; then
      relative=$(echo "${f}" | sed "s|${to_symlink_dir}/||g")
      relative_dir=$(dirname ${relative})

      src="${to_symlink_dir}/${relative}"
      dst="${HOME}/.${relative}"

      if [ "${relative_dir}" != '.' ]; then
        dest_rel_dir="${HOME}/.${relative_dir}"
        if [ ! -d "${dest_rel_dir}" ]; then
            rm -rf $dest_rel_dir
        fi
        mkdir -p "${HOME}/.${relative_dir}"
      fi
      printf "Symlinking '${relative}':\n  src: ${src}\n  dst: ${dst}\n\n"
      rm -rf $dst
      ln -s $src $dst
    fi
done
