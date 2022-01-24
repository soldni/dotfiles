#!/bin/bash

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

to_ignore=(
    'scripts' 'vim' '.zlogin' 'win-bootstrap.sh' 'Alfred.alfredpreferences'
    'bootstrap.sh' '..' '.' 'ssh.rc' 'other' 'install.sh' '.git'
    '.gitignore' 'README.md' 'setup.sh' 'fix_newline_windows.py'
    '.minttyrc' 'cygwin.bkp' 'rc.local' 'macos_setup.sh'
)

current=$(pwd)

to_symlink_to_home="$(ls home-symlink)"

git config pull.rebase false

for f in $to_symlink_to_home
do
    valid=$(array_contains to_ignore "${f}" && echo 0 || echo 1)
    if [[ "$valid" -gt 0 &&  $f != '*.bkp' && $f != '*.swp' ]]
    then
        echo "symlinking \"$f\"..."
        rm -rf "$HOME/.$f" 2> /dev/null
        chmod 755 "${current}/home-symlink/${f}"
        ln -s "${current}/home-symlink/${f}" "${HOME}/.${f}"
    fi
done


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

rm -rf "$HOME/.ssh/rc" 2> /dev/null
ln -s "$current/ssh.rc" "$HOME/.ssh/rc"

# create a local folder
echo "making \".local/scripts\" folder..."
mkdir -p "${HOME}/.local"
rm -rf "${HOME}/.local/scripts" 2> /dev/null
ln -s "${current}/scripts" "${HOME}/.local/scripts"

# vim setup
if [ ! -d "$HOME/.vim" ]; then
    mkdir -p $HOME/.vim
    mkdir -p $HOME/.vim/pack
    mkdir -p $HOME/.vim/tmp
fi

# install pathogen for vim
if [ ! -f "${HOME}/.vim/autoload/pathogen.vim" ]; then
    echo "Installing Pathogen for vim..."
    mkdir -p ${HOME}/.vim/autoload ${HOME}/.vim/bundle && \
        curl -LSso ${HOME}/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
fi

plugins=(
    'https://github.com/vim-airline/vim-airline'
    'https://github.com/vim-airline/vim-airline-themes'
    'https://github.com/soldni/dracula-vim'
    'https://github.com/scrooloose/nerdtree'
    'https://github.com/mkitt/tabline.vim'
    'https://github.com/tpope/vim-fugitive'
    'https://github.com/svermeulen/vim-easyclip'
    'https://github.com/tpope/vim-repeat'
    'https://github.com/vim-syntastic/syntastic'
    'https://github.com/heavenshell/vim-pydocstring'
    'https://github.com/lervag/vimtex'
    'https://github.com/ervandew/supertab'
    'https://github.com/flazz/vim-colorschemes'
    'https://github.com/terryma/vim-multiple-cursors'
    'https://github.com/tpope/vim-eunuch'
    'https://github.com/tpope/vim-commentary'
)

mkdir -p $HOME/.vim/bundle
cd $HOME/.vim/bundle
for plugin in "${plugins[@]}"; do
    plugin_dir=$(basename ${plugin})
    set +e
    if [ ! -d $plugin_dir ]; then
        echo "cloning \"${plugin_dir}\"..."
        git clone --recursive ${plugin} $plugin_dir
    else
         echo "updating \"${plugin_dir}\"..."
        cd ${plugin_dir}
        git pull
        cd ..
    fi
    set -e
done

cd ${current}

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

echo "${BASH_SOURCE[0]}: done!"
