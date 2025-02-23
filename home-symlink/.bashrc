#!/usr/bin/env bash

# System-wide .bashrc file for interactive bash(1) shells.
if [ -z "$PS1" ]; then
   return
fi


if [[ ! -z "${ZSH_NAME}" ]]; then
    CURRENT_SHELL_NAME='zsh'
elif [[ ! -z "${BASH}" ]]; then
    CURRENT_SHELL_NAME='bash'
elif [[ ! -z "${version}" ]]; then
    CURRENT_SHELL_NAME='tcsh'
elif [[ ! -z "${shell}" ]]; then
    CURRENT_SHELL_NAME=$(basename ${shell})
else
    # last resort
    CURRENT_SHELL_NAME=$(echo $0 | sed 's/\-//g' )
fi

# execute machine specific bash script
source "$HOME/.prelocalrc"

export HOSTNAME=`hostname`
export TERM=screen-256color

if [[ "${CURRENT_SHELL_NAME}" == "bash" ]]; then
    # Make bash check its window size after a process completes
    shopt -s checkwinsize
elif [[ "${CURRENT_SHELL_NAME}" == "zsh" ]]; then
    setopt PROMPT_SUBST
    bindkey -e
    bindkey "[D" backward-word
    bindkey "[C" forward-word
    # bindkey "^[a" beginning-of-line
    # bindkey "^[e" end-of-line
fi

# Tell the terminal about the working directory at each prompt.
if [[ "${TERM_PROGRAM}" == "Apple_Terminal" ]] && [[ -z "${INSIDE_EMACS}" ]]; then
    update_terminal_cwd() {
        # dentify the directory using a "file:" scheme URL,
        # including the host name to disambiguate local vs.
        # remote connections. Percent-escape spaces.
	local SEARCH=' '
	local REPLACE='%20'
	local PWD_URL="file://$HOSTNAME${PWD//$SEARCH/$REPLACE}"
	printf '\e]7;%s\a' "$PWD_URL"
    }
    PROMPT_COMMAND="update_terminal_cwd; $PROMPT_COMMAND"
fi


if [[ "${CURRENT_SHELL_NAME}" == "zsh" ]]; then
    # make tab completion case insesitive
    autoload -Uz compinit && compinit
    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
    export CASE_SENSITIVE="false"

    # add extra fuction to time command;
    # from https://superuser.com/a/767491
    if [[ `uname` == Darwin ]]; then
        MAX_MEMORY_UNITS=KB
    else
        MAX_MEMORY_UNITS=MB
    fi

    TIMEFMT="%J
    %U  user %S system %P cpu %*E total
    avg shared (code):         %X KB
    avg unshared (data/stack): %D KB
    total (sum):               %K KB
    max memory:                %M $MAX_MEMORY_UNITS
    page faults from disk:     %F
    other page faults:         %R"
fi


###############################
# SET OS SPECIFIC COMMANDS HERE

if [[ "$OSTYPE" == "darwin"* ]]; then
    # We're on macos

    # don't want to hear about bash being deprecated
    export BASH_SILENCE_DEPRECATION_WARNING=1

    # this is useful for brew
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

    # use openjdk if that's what the system has
    if [ -d "/opt/homebrew/opt/openjdk" ]; then
        export PATH="/opt/homebrew/opt/openjdk/bin:${PATH}"
        export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include:${CPPFLAGS}"
        export JAVA_HOME="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home/"
    fi

    # add command to remove all apps from dock
    alias dock-remove-all="defaults write com.apple.dock persistent-apps -array"

    # upgrade remotely
    alias macos-reboot='sudo fdesetup authrestart'
    alias macos-reboot-delay='sudo fdesetup authrestart -delayminutes -1'
    alias macos-run-software-update='sudo softwareupdate --install -a'
    alias macos-run-software-update-and-reboot='sudo fdesetup authrestart -delayminutes -1 && sudo softwareupdate --install -a --restart'

    # add a space to the dock
    alias dock-spacer="defaults write com.apple.dock persistent-apps -array-add '{\"tile-type\"=\"spacer-tile\";}'; killall Dock"

    # add path to ruby
    MACOS_RUBY_PATH=/opt/homebrew/opt/ruby/bin
    if [ -d "${MACOS_RUBY_PATH}" ]; then
        export PATH="${MACOS_RUBY_PATH}:${PATH}"
    fi

    # makes sure that pkg-config works properly
    if [ -d "/usr/local/lib/pkgconfig" ]; then
        export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
    fi

    # adding brew to path
    if [ -d "/opt/homebrew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        export PATH="/opt/homebrew/sbin:$PATH"
    fi

    # add command to quickly unlock keychain for macOS
    if [ -d "${HOME}/Library/Keychains" ]; then
        function unlock-login-keychain {
            security unlock-keychain "${HOME}/Library/Keychains/login.keychain-db"
        }
    fi

    # override all gnubin when available
    OPTBASE="/opt/homebrew/opt"
    if [ -d "${OPTBASE}" ]; then
        for fn in $(ls --color=no $OPTBASE); do
            gnubin="${OPTBASE}/${fn}/libexec/gnubin"
            gnuman="${OPTBASE}/${fn}/libexec/gnuman"
            if [ -d "${gnubin}" ]; then
                export PATH="${gnubin}:$PATH"
                export MANPATH="${gnumain}:$MANPATH"
            fi
        done
    fi

    # export path to openblas if it is installed
    export OPENBLAS="$(brew --prefix openblas 2&> /dev/null)"

fi
if [[ "$OSTYPE" == "linux"* ]]; then
    alias hdtemp="hddtemp /dev/sd[abcdefghi]"
fi

###############################


# add both local and .local to the path
if [ -d "$HOME/local" ]; then
    export PATH="$HOME/local/bin:$PATH"
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOME}/local/lib"
fi
if [ -d "$HOME/.local" ]; then
    export PATH="$HOME/.local/bin:$PATH"
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:$HOME/.local/lib"
fi


# Tell ls to be colourful
export CLICOLOR=1

# set vim as the default editor
export VISUAL=vim
export EDITOR=vim

# ls behaves like ll in fish
alias ls='ls --color=auto'

export PYENV_ROOT="$HOME/.pyenv"
# activate pyenv
if [[ -d "$PYENV_ROOT" ]]; then
    export PATH=$PYENV_ROOT/bin:$PATH
    eval "$(pyenv init -)"
fi

# command to stop/start ec2 quickly
has_aws_cli=$(which aws 2>/dev/null)
if [[ ! -z $has_aws_cli ]]; then
    function ec2-list {
        aws ec2 describe-instances --output json | jq -r '.Reservations[].Instances[] | [.InstanceId,.PublicDnsName,.State.Name,(.Tags[] | select(.Key == "Name") | .Value)] | @csv'
    }
    function ec2-stop {
        aws ec2 stop-instances --instance-ids ${1}
    }
    function ec2-boot {
        aws ec2 start-instances --instance-ids ${1}
    }
    function ec2-desc {
        aws ec2 describe-instances --instance-ids ${1} | jq '.Reservations[0]' -M
    }
    function aws-cred-to-env {
        # get profile from input if provided, otherwise set it to "default"
        if [[ -z $1 ]]; then
            profile="default"
        else
            profile="$1"
        fi

        export AWS_ACCESS_KEY_ID=$(aws configure get ${profile}.aws_access_key_id)
        export AWS_SECRET_ACCESS_KEY=$(aws configure get ${profile}.aws_secret_access_key)
    }
fi


# command to quickly build and run a container
has_docker=$(which docker 2>/dev/null)
if [[ ! -z $has_docker ]]; then
    alias docker-build-and-run='docker run --rm -it $(docker build -q .)'
fi


# tmux shortcuts
function ta { if [ -z ${1} ]; then tmux -2 attach; else tmux -2 attach -t ${1}; fi }
function tn { if [ -z ${1} ]; then tmux -2; else tmux -2 new -s ${1}; fi }
function tl { tmux -2 list-sessions; }

alias git-freeze='git update-index --assume-unchanged'
alias git-unfreeze='git update-index --no-assume-unchanged'
alias git-undo='git reset --soft HEAD~1'

# increase bash history file size
HISTFILESIZE=50000

# bootstrap miniforge
if [ -d "${HOME}/miniforge3" ]; then
    # initialization of miniforge
    __conda_setup="$("${HOME}/miniforge3/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "${HOME}/miniforge3/etc/profile.d/conda.sh" ]; then
            . "${HOME}/miniforge3/etc/profile.d/conda.sh"
        else
            export PATH="${HOME}/miniforge3/bin:$PATH"
        fi
    fi
    unset __conda_setup
fi


# add scripts folder to path
for SCRIPT_DIR in ".local/scripts" ".local/share/scripts"; do
    if [ -d "${HOME}/${SCRIPT_DIR}" ]; then
        export PATH="${PATH}:${HOME}/${SCRIPT_DIR}"
    fi
done


# toggles for bash history
alias history-off='set +o history'
alias history-on='set -o history'


# Shortcuts to common linting tools in python
function pypretty () {
    path_to_process="${1}"

    if [ -z "${path_to_process}" ]; then
        path_to_process="."
    fi

    has_isort=$(which isort 2>/dev/null)
    if [[ -z ${has_isort} ]]; then
        echo 'isort not found. Please run `pip install isort`' > /dev/stderr
        return
    fi

    has_black=$(which black 2>/dev/null)
    if [[ -z ${has_black} ]]; then
        echo 'black not found. Please run `pip install black`' > /dev/stderr
        return
    fi

    isort ${path_to_process} && black ${path_to_process}
}


# get indices of headers
tsv-header () { head -n 1 $* | tr $'\t' '\n' | nl ; }
csv-header () { head -n 1 $* | tr ',' '\n' | nl ; }

# mute the fucking bell
setterm -blength 0 >/dev/null 2>&1


#so as not to be disturbed by Ctrl-S ctrl-Q in terminals:
stty -ixon

# better copy (uses rsync for progressbar shit)
alias copy='rsync -rva --info=progress2'

if [ -z "${JAVA_HOME}" ]; then
    # set java home if JDK is installed
    has_java=$(which javac 2>/dev/null)

    if [[ ! -z $has_java ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macos has symlinks for javac, but that
            # does not mean java is installed. Checking again
            has_java=$(javac 2> /dev/null)
            if [[ ! -z $has_java ]]; then
                export JAVA_HOME=$(/usr/libexec/java_home)
            fi
        else
            export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
        fi
    fi
fi

# log4j vulnerability fix
export JAVA_TOOLS_OPTIONS="-Dlog4j2.formatMsgNoLookups=true"

# shortcuts for git submodules
alias git-clone-submodules="git clone --recursive -j8"
alias git-init-submodules="git submodule update --init --recursive"
alias git-pull-submodules="git pull --recurse-submodules"
alias git-rm-submodule="submodule deinit"

# Use bash-completion if available
if [[ "${CURRENT_SHELL_NAME}" == "bash" ]]; then
    [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
    [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
    [[ -r "/etc/profile.d/bash_completion.sh" ]] && . "/etc/profile.d/bash_completion.sh"
fi


# if you have acme.sh installed for
# Let's Encrypt, add it to the path
if [ -d "$HOME/.acme.sh" ]; then
    . "${HOME}/.acme.sh/acme.sh.env"
fi

# fuction to get what's changed
get_dirty_git() {
    porcelain=$(git status --porcelain 2>/dev/null)

    if [ -z "${porcelain}" ]; then
        git_sync_status="$(git status 2>/dev/null)"
        git_ahead=$(echo "${git_sync_status}" | grep 'Your branch is ahead')
        if [ ! -z "${git_ahead}" ]; then
            echo 'P'
        else
            echo ''
        fi
    else
        git_status=""
        if ([ ! -z "$(echo $porcelain | grep 'M ')" ] || [ ! -z "$(echo $porcelain | grep 'R ')" ]); then
            # Modified/renamed
            git_status="S${git_status}"
        fi
        if ([ ! -z "$(echo $porcelain | grep '? ')" ] || [ ! -z "$(echo $porcelain | grep 'A ')" ]); then
            # Added/to add
            git_status="I${git_status}"
        fi
        if [ ! -z "$(echo $porcelain | grep 'D ')" ]; then
            # Deleted
            git_status="D${git_status}"
        fi

        if [ -z $git_status ]; then
            git_status="O"
        fi

        echo $git_status
    fi
}

# get the name of the branch we are in
parse_git_branch() {
    if [ ! -d '.git' ]; then
        # exit if we are not in a git repo
        return
    fi

    branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    if [ ! -z "${branch}" ]; then
        dirty="$(get_dirty_git)"
        if [ -z "${dirty}" ]; then
            echo "${branch}"
        else
            echo "${branch} [${dirty}]"
        fi
    fi
}

# shorter prompt
short_pwd() {
    cwd=$(pwd | perl -F/ -ane 'print join( "/", map { $i++ < @F - 1 ?  substr $_,0,1 : $_ } @F)')
    echo -n $cwd
}


# We want to have the ability to set a custom hostname
# that will make the machine easier to identify
if [ -z "${CUSTOM_HOSTNAME}" ]; then
    export CUSTOM_HOSTNAME=$(hostname)
fi

# sometimes binaries are installed in this directory in macos, so we
# add it to the path if we find any binary files.
if [ -d "${HOME}/Library/Python" ]; then
    for python_install in $(ls --color=no "${HOME}/Library/Python"); do
        if [ -d "${HOME}/Library/Python/${python_install}/bin" ]; then
            export PATH="${HOME}/Library/Python/${python_install}/bin:${PATH}"
        fi
    done
fi

# set this variable to anything but the empty string to enable
# hostname-based prompt coloring in bash/zsh
HOST_BASED_PROMPT_COLORS=''

if [ -z "${HOST_BASED_PROMPT_COLORS}" ]; then
    # use the standard mapping for colors
    # uses either dircolors or gdircolors if they are available
    has_dircolors=$(which dircolors 2>/dev/null)
    has_gdircolors=$(which gdircolors 2>/dev/null)

    if [ ! -z "${has_dircolors}" ]; then
        eval "$(dircolors -b)"
    elif [ ! -z "${has_gdircolors}" ]; then
        eval "$(gdircolors -b)"
    fi
else
    hostcolor="38;2;$(rgb_color_generator.py -r)"
    greycolor="38;5;247"

    # some custom LS_COLORS to match the prompt
    export LS_COLORS="di=${hostcolor}:ln=${greycolor}:or=${greycolor}:so=${greycolor}:su=${greycolor}:sg=${greycolor}:ow=${greycolor}:tw=${greycolor}:ex=${hostcolor}:mi=${greycolor}"
fi

# Remove the bold attribute from the colors
export LS_COLORS="$(echo $LS_COLORS | tr ':' '\n' | sed 's/1;/0;/g' | tr '\n' ':')"

if [[ "${CURRENT_SHELL_NAME}" == "bash" ]]; then
    reset_color='\[\e[m\]'

    if [ -z "${HOST_BASED_PROMPT_COLORS}" ]; then
        magenta_color='\[\e[35m\]'
        green_color='\[\e[32m\]'
        yellow_color='\[\e[33m\]'
        blue_color='\[\e[34m\]'
        cyan_color='\[\e[36m\]'
        black_color='\[\e[m\]'

    else
        # we use the host color everywhere
        magenta_color="\[\033[${hostcolor}m\]"
        green_color="\[\033[${hostcolor}m\]"
        yellow_color="\[\033[${hostcolor}m\]"
        blue_color="\[\033[${hostcolor}m\]"

        # instead of black, we use this grey
        black_color="\[\033[${greycolor}m\]"
        cyan_color="\[\033[${greycolor}m\]"
    fi

    # notice how we need to escape the dollar sign, otherwise it doesn't get evaluated every time the prompt is re-drawn!
    export PS1="${magenta_color}\u ${black_color}on ${green_color}${CUSTOM_HOSTNAME} ${black_color}in ${yellow_color}\$(short_pwd) ${black_color}at ${blue_color}\D{%F %H:%M} ${black_color}\$(parse_git_branch)${cyan_color}\n\\$ ${reset_color}"


elif [[ "${CURRENT_SHELL_NAME}" == "zsh" ]]; then

    # follow bash style delete
    autoload -U select-word-style
    select-word-style bash

    # same as before, but for zsh
    new_line_symbol=$'\n'
    lambda_symbol=$'\u03bb'
    no_color='%f'

    if [ -z "${HOST_BASED_PROMPT_COLORS}" ]; then
        magenta_color='%F{magenta}'
        green_color='%F{green}'
        yellow_color='%F{yellow}'
        blue_color='%F{blue}'
        cyan_color='%F{cyan}'

        # this is the default color
        black_color='%f'

    else
        magenta_color="%{$(echo -ne "\033[${hostcolor}m")%}"
        green_color="%{$(echo -ne "\033[${hostcolor}m")%}"
        yellow_color="%{$(echo -ne "\033[${hostcolor}m")%}"
        blue_color="%{$(echo -ne "\033[${hostcolor}m")%}"

        # instead of black, we use this grey
        cyan_color="%{$(echo -ne "\033[${greycolor}m")%}"
        black_color="%{$(echo -ne "\033[${greycolor}m")%}"
    fi

    export PS1="${magenta_color}%n ${black_color}on ${green_color}$CUSTOM_HOSTNAME ${black_color}in ${yellow_color}\$(short_pwd) ${black_color}at ${blue_color}%D %T ${black_color}\$(parse_git_branch)${new_line_symbol}${cyan_color}${lambda_symbol}${no_color} "
fi


# returns a random hash based on current time, machine name, and user
random_hash() {
    echo "${USER}_${HOSTNAME}_$(date)" | md5sum | cut -f1 -d ' '
}


if [[ "${CURRENT_SHELL_NAME}" == "zsh" ]]; then
    macos_autosuggest='/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
    if [[ -f "${macos_autosuggest}" ]]; then
        source "${macos_autosuggest}"
    fi
fi

#######################################
########### SSH AGENT SNAFU ###########

SSH_ENV_LOC="${HOME}/.ssh/environment"
SSH_KEY_LOC="${HOME}/.ssh/id_rsa"

# Check if we have a private key; if not, we don't care about
# the ssh agent.
if [ -f "${SSH_KEY_LOC}" ]; then
    if [ -f "${SSH_ENV_LOC}" ]; then
        # An ssh agent is registered in the environment file;
        # let's see if it is still running
        IFS='=' read -r _ ENV_AGENT_PID <<< "$(cat ${SSH_ENV_LOC} | grep -oE 'SSH_AGENT_PID=[0-9]+' | cut -d ';' -f 1)"

        # this is the lovcation where the socket for the agent is...
        IFS='=' read -r _ ENV_SOCK <<< "$(cat ${SSH_ENV_LOC} | grep -oE 'SSH_AUTH_SOCK=(/[^/ ]*)+/?' | sed 's/;$//')"

        # this will be empty if the agent is not running anymore
        USE_OLD_AGENT=$(ps -ef | grep "${ENV_AGENT_PID}" | grep 'ssh-agent')

        # The old socket has been deleted; so we kill the old agent and start a new one
        if  [ "${USE_OLD_AGENT}" != "" ] && [ ! -S "${ENV_SOCK}" ]; then
            echo "Socket disconnected for SSH agent ${ENV_AGENT_PID}; killing..."
            USE_OLD_AGENT=""
        fi
    fi

    if [[ "${USE_OLD_AGENT}" == "" ]]; then
        echo "Starting new SSH agent..."

        # we need to start a new agent!
        ssh-agent -s > "${SSH_ENV_LOC}"

        # gotta protect the agent
        chmod 700 ${SSH_ENV_LOC}
    else
        echo "Reconnecting to SSH agent PID ${ENV_AGENT_PID}..."
    fi

    # ssh agent running will be empty if everything
    eval $(cat "${SSH_ENV_LOC}") > /dev/null

    if [ ! -z "${SSH_AUTH_SOCK}" ] && [ ! -z "$(ssh-add -L | grep 'has no identities')" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then

            # since macOS 12.x, `-K` is deprecated, so we use the new
            # command instead. Use `-K` on older version
            MACOS_MAJOR_VERSION="$(sw_vers| grep -oP '\d+\.\d+' | cut -d '.' -f 1)"
            USING_MACOS_SSH="$(if [[ "$(which ssh-add)" == '/usr/bin/ssh-add' ]]; then echo 1; else echo 0; fi)"
            if [[ $MACOS_MAJOR_VERSION -gt 12 ]]; then
                ssh-add --apple-use-keychain
            elif [ $USING_MACOS_SSH -eq 1 ]; then
                # this only works when using macos's built in ssh client
                ssh-add -K
            else
                ssh-add
            fi
        else
            ssh-add
        fi
    fi
fi

####### END OF SSH AGENT SNAFU ########
#######################################

# this is for supporting nvm
if [ -d "${HOME}/.nvm" ]; then
   export NVM_DIR="$HOME/.nvm"
   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
   [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# Rust
if [ -f "${HOME}/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# AI2ools
if [ -d "/opt/ai2ools" ]; then
    export PATH="${PATH}:/opt/ai2ools/bin"
fi


# Activate bash integration in iTerm2
if [ -f "${HOME}/.iterm2_shell_integration.bash" ]; then
    source "${HOME}/.iterm2_shell_integration.bash"
elif [ -f "${HOME}/.iterm2_shell_integration.zsh" ]; then
    source "${HOME}/.iterm2_shell_integration.zsh"
fi

if [[ "${CURRENT_SHELL_NAME}" == "bash" ]]; then
    # The next line updates PATH for the Google Cloud SDK.
    if [ -f "${HOME}/.local/google-cloud-sdk/path.bash.inc" ]; then
        source "${HOME}/.local/google-cloud-sdk/path.bash.inc"
    fi

    # The next line enables shell command completion for gcloud.
    if [ -f "${HOME}/.local/google-cloud-sdk/completion.bash.inc" ]; then
        source "${HOME}/.local/google-cloud-sdk/completion.bash.inc"
    fi
elif [[ "${CURRENT_SHELL_NAME}" == "zsh" ]]; then
    # The next line updates PATH for the Google Cloud SDK.
    if [ -f "${HOME}/.local/google-cloud-sdk/path.zsh.inc" ]; then
        source "${HOME}/.local/google-cloud-sdk/path.zsh.inc"
    fi

    # The next line enables shell command completion for gcloud.
    if [ -f "${HOME}/.local/google-cloud-sdk/completion.zsh.inc" ]; then
        source "${HOME}/.local/google-cloud-sdk/completion.zsh.inc"
    fi
fi


# execute machine specific bash script
source "$HOME/.postlocalrc"
. "$HOME/.cargo/env"
