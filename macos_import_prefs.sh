#!/usr/bin/env bash

# location of this script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# import Preferences
for fn in $(ls "${script_dir}/dotsecrets/Preferences"); do
    echo "Importing ${fn} to Preferences"
    defaults import ${fn} "${script_dir}/dotsecrets/Preferences/${fn}"
done

# import Application Support
for fn in $(ls "${script_dir}/dotsecrets/Application Support"); do
    echo "Importing ${fn} to Application Support"
    mv "${HOME}/Library/Application Support/${fn}" \
        "${HOME}/.Trash/$(date -u +"%Y-%m-%dT%H:%M:%SZ" | sed 's/\:/_/g')-${fn}"
    cp -r "${script_dir}/dotsecrets/Application Support/${fn}" "${HOME}/Library/Application Support/${fn}"
done
