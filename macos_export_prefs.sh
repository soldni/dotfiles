#!/usr/bin/env bash

# location of this script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# export data in preferences
for fn in $(ls "${script_dir}/dotsecrets/Preferences"); do
    echo "Exporting ${fn} to Preferences"
    mv "${script_dir}/dotsecrets/Preferences/${fn}" \
         "${HOME}/.Trash/$(date --iso-8601=seconds | sed 's/\:/_/g')-${fn}"
    defaults export ${fn} "${script_dir}/dotsecrets/Preferences/${fn}"
done

# export data in application support
for fn in $(ls "${script_dir}/dotsecrets/Application Support"); do
    echo "Exporting ${fn} to Application Support"
    mv "${script_dir}/dotsecrets/Application Support/${fn}" \
        "${HOME}/.Trash/$(date --iso-8601=seconds | sed 's/\:/_/g')-${fn}"
    cp -r "${HOME}/Library/Application Support/${fn}" "${script_dir}/dotsecrets/Application Support/${fn}"
done
