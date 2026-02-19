#!/usr/bin/env bash

# Backup or restore IDE extensions for VS Code and Cursor.

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

usage() {
    echo "Usage: $0 {backup|restore} [code|cursor]"
    exit 1
}

[[ $# -ge 1 && $# -le 2 ]] || usage

command="$1"
[[ "$command" == "backup" || "$command" == "restore" ]] || usage

filter_cli="${2:-}"
if [[ -n "$filter_cli" && "$filter_cli" != "code" && "$filter_cli" != "cursor" ]]; then
    usage
fi

# Map CLI name -> extensions.txt path
declare -A cli_ext_file
cli_ext_file[code]="${script_dir}/home-symlink/Library/Application Support/Code/User/extensions.txt"
cli_ext_file[cursor]="${script_dir}/home-symlink/Library/Application Support/Cursor/User/extensions.txt"

target_clis=( ${filter_cli:-code cursor} )

available_clis=()
for cli in "${target_clis[@]}"; do
    if command -v "$cli" &>/dev/null; then
        available_clis+=("$cli")
        echo "Found $cli CLI."
    else
        echo "Warning: $cli CLI not found, skipping."
    fi
done

if [[ ${#available_clis[@]} -eq 0 ]]; then
    echo "Error: Neither 'code' nor 'cursor' CLI is available."
    exit 1
fi

for cli in "${available_clis[@]}"; do
    ext_file="${cli_ext_file[$cli]}"

    if [[ "$command" == "backup" ]]; then
        echo "Backing up $cli extensions to ${ext_file}..."
        "$cli" --list-extensions > "$ext_file"
        echo "Saved $(wc -l < "$ext_file" | tr -d ' ') extensions."

    elif [[ "$command" == "restore" ]]; then
        if [[ ! -f "$ext_file" ]]; then
            echo "Warning: ${ext_file} not found, skipping $cli restore."
            continue
        fi

        echo "Uninstalling all $cli extensions..."
        "$cli" --list-extensions | xargs -L 1 "$cli" --uninstall-extension || true

        echo "Installing $cli extensions from ${ext_file}..."
        cat "$ext_file" | xargs -L 1 "$cli" --install-extension

        echo "Restored $(wc -l < "$ext_file" | tr -d ' ') extensions for $cli."
    fi
done

echo "Done."
