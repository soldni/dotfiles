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

# vim setup
if [ ! -d "$HOME/.vim" ]; then
    mkdir -p $HOME/.vim
    mkdir -p $HOME/.vim/pack
    mkdir -p $HOME/.vim/tmp
fi

# setup tsv-utils
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Configuring macOS to my liking..."
    curl -L "https://github.com/eBay/tsv-utils/releases/download/v2.2.0/tsv-utils-v2.2.0_osx-x86_64_ldc2.tar.gz" | tar xz
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
