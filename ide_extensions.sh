#!/usr/bin/env bash

# Back up or restore VS Code, Cursor, and Fresh configuration.

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

usage() {
    echo "Usage: $0 {backup|restore} [code|cursor|fresh]" >&2
    echo "VS Code/Cursor: extensions.txt, settings.json, and keybindings.json." >&2
    echo "Fresh: config.json, tsconfig.json, and optional init.ts." >&2
    exit 1
}

[[ $# -ge 1 && $# -le 2 ]] || usage

command="$1"
[[ "$command" == "backup" || "$command" == "restore" ]] || usage

filter_cli="${2:-}"
if [[ -n "$filter_cli" && "$filter_cli" != "code" && "$filter_cli" != "cursor" && "$filter_cli" != "fresh" ]]; then
    usage
fi

# VS Code and Cursor use platform-specific live config directories.
case "${OSTYPE}" in
    darwin*) config_root="${HOME}/Library/Application Support" ;;
    linux*) config_root="${XDG_CONFIG_HOME:-${HOME}/.config}" ;;
    *)
        config_root=""
        echo "Warning: Settings and keyboard shortcuts are unsupported on ${OSTYPE}, skipping them." >&2
        ;;
esac

target_clis=(code cursor fresh)
if [[ -n "${filter_cli}" ]]; then
    target_clis=("${filter_cli}")
fi

for cli in "${target_clis[@]}"; do
    case "${cli}" in
        code) app_name="Code" ;;
        cursor) app_name="Cursor" ;;
    esac
    if [[ "${cli}" == "fresh" ]]; then
        # Keep Fresh outside home-symlink so its config stays as regular files.
        repo_user_dir="${script_dir}/fresh"
        live_user_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/fresh"
        config_files=(config.json tsconfig.json init.ts)
    else
        repo_user_dir="${script_dir}/home-symlink/Library/Application Support/${app_name}/User"
        live_user_dir="${config_root:+${config_root}/${app_name}/User}"
        config_files=(settings.json keybindings.json)
    fi

    # Config files can be copied even when the editor CLI is unavailable.
    if [[ -n "${live_user_dir}" ]]; then
        if [[ "${command}" == "backup" ]]; then
            source_dir="${live_user_dir}"
            destination_dir="${repo_user_dir}"
        else
            source_dir="${repo_user_dir}"
            destination_dir="${live_user_dir}"
        fi

        # Preserve other local files when migrating a symlinked Fresh directory.
        if [[ "${cli}" == "fresh" && "${command}" == "restore" && -L "${destination_dir}" ]]; then
            fresh_tmp_dir="$(mktemp -d "${destination_dir}.XXXXXX")"
            if [[ -d "${destination_dir}" ]]; then
                cp -RL "${destination_dir}/." "${fresh_tmp_dir}/"
            fi
            rm "${destination_dir}"
            mv "${fresh_tmp_dir}" "${destination_dir}"
        fi

        for config_file in "${config_files[@]}"; do
            source_file="${source_dir}/${config_file}"
            destination_file="${destination_dir}/${config_file}"
            if [[ ! -f "${source_file}" ]]; then
                if [[ "${cli}" == "fresh" && "${config_file}" == "init.ts" ]]; then
                    continue
                fi
                echo "Warning: ${source_file} not found, skipping." >&2
                continue
            fi
            # Remove the link itself, including dangling links from the old tree.
            if [[ "${cli}" == "fresh" && "${command}" == "restore" && -L "${destination_file}" ]]; then
                rm "${destination_file}"
            fi
            # home-symlink.sh may already link the live file to this backup.
            if [[ "${source_file}" -ef "${destination_file}" ]]; then
                echo "${cli} ${config_file} already points to the repo file, skipping."
                continue
            fi

            mkdir -p "${destination_dir}"
            echo "Copying ${source_file} to ${destination_file}..."
            cp "${source_file}" "${destination_file}"
        done
    fi

    # Fresh configuration is file-based; it has no VS Code extension CLI.
    if [[ "${cli}" == "fresh" ]]; then
        continue
    fi
    ext_file="${repo_user_dir}/extensions.txt"

    if ! command -v "${cli}" &>/dev/null; then
        echo "Warning: ${cli} CLI not found, skipping extensions ${command}." >&2
        continue
    fi

    if [[ "$command" == "backup" ]]; then
        mkdir -p "${repo_user_dir}"
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
