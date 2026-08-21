#!/bin/bash

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

set -e

echo "Setting up environment..."

# this function checks if an array contains an element
# from https://stackoverflow.com/a/14367368 usage:
#   array_contains arr "a b"  && echo yes || echo no    # no
#   array_contains arr "d e"  && echo yes || echo no    # yes
array_contains () {
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array}"; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

# create pre- and post-localrc
if [ ! -f "${HOME}/.prelocalrc" ]; then
    touch "${HOME}/.prelocalrc"
fi
if [ ! -f "${HOME}/.postlocalrc" ]; then
    touch "${HOME}/.postlocalrc"
fi

if [ ! -d "${HOME}/.ssh" ]; then
    mkdir "$HOME/.ssh"
fi

bash ${SCRIPT_DIR}/home-symlink.sh

# setup GitHub Copilot CLI
has_copilot=$(which copilot 2>/dev/null || true)
if [ -n "${has_copilot}" ]; then
    has_jq=$(which jq 2>/dev/null || true)
    if [ -z "${has_jq}" ]; then
        echo "ERROR: jq is required to configure GitHub Copilot CLI." >&2
        exit 1
    fi

    copilot_settings_dir="${HOME}/.copilot"
    copilot_settings_file="${copilot_settings_dir}/settings.json"
    mkdir -p "${copilot_settings_dir}"
    copilot_settings_tmp=$(mktemp "${copilot_settings_file}.tmp.XXXXXX")
    copilot_settings_filter='. + {
        "colorMode": "default",
        "theme": "default",
        "experimental": true,
        "logLevel": "default",
        "reasoningEffort": "xhigh",
        "defaultMode": "autopilot",
        "defaultPermissionMode": "assisted",
        "showTipsOnStartup": true
    }'

    if {
        if [ -f "${copilot_settings_file}" ]; then
            "${has_jq}" "${copilot_settings_filter}" "${copilot_settings_file}"
        else
            "${has_jq}" --null-input "${copilot_settings_filter}"
        fi
    } > "${copilot_settings_tmp}"; then
        mv "${copilot_settings_tmp}" "${copilot_settings_file}"
    else
        rm -f "${copilot_settings_tmp}"
        echo "ERROR: failed to update ${copilot_settings_file}." >&2
        exit 1
    fi
fi

# setup tsv-utils
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Configuring macOS to my liking..."
    curl -L "https://github.com/eBay/tsv-utils/releases/download/v2.2.1/tsv-utils-v2.2.1_osx-x86_64_ldc2.tar.gz" | tar xz
elif [[ "$OSTYPE" == "linux"* ]]; then
    curl -L "https://github.com/eBay/tsv-utils/releases/download/v2.2.0/tsv-utils-v2.2.0_linux-x86_64_ldc2.tar.gz" | tar xz
fi
cd tsv-utils*
mkdir -p "${HOME}/.local/bin"
cp bin/* "${HOME}/.local/bin/"
cd ..
rm -rf tsv-utils*


# for the next command, exit on error must be disabled
set +e

# check if bc is installed; we need it for tmux!
has_bc=$(which bc 2>/dev/null)
if [ -z "${has_bc}" ]; then
    echo "WARNING: your system doesn't appear to have bc installed!"
fi

echo "${SOURCE}: done!"
