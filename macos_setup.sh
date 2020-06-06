#!/usr/bin/env bash

# This script runs several plist config command to get a mac to my liking.

set -x

# location of this script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# configure custom keyboard shortcuts
# from http://hints.macworld.com/article.php?story=20131123074223584
# and https://ryanmo.co/2017/01/05/setting-keyboard-shortcuts-from-terminal-in-macos/
# meta-keys are set as @ for Command, $ for Shift, ~ for Alt and ^ for Ctrl
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Paste and Match Style" "@~\$v"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Paste Special…" "@~\$v"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Save as PDF" "@p"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Save as PDF\\U2026" "@p"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Merge All Windows" "@u"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Show Help Menu" "~\\U0020"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Edit Tab Title" "@~^e"

# set it up so that CMD+W doesn't close Amazon Chime windows anymore
defaults write com.amazon.Amazon-Chime NSUserKeyEquivalents -dict-add "Hide Tab" "@\$w"

# add a shortcut for quip to show/hide tab
defaults write com.quip.Desktop NSUserKeyEquivalents -dict-add "Always Show Sidebar" "@~T"

# change shortcut to achive for Apple Mail
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Archive" '@$A'

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Configure dock, expose, and dashboard
defaults write com.apple.dashboard mcx-disabled -boolean no
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock orientation -string bottom
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-time-modifier -float 0.1
defaults write com.apple.dock mouse-over-hilite-stack -bool true
killall Dock

# Low font smoothing
defaults -currentHost write -globalDomain AppleFontSmoothing -int 1


# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Customize trackpad to my liking
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFiveFingerPinchGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -int 1

# Do not create .DS_Store files on remote disks
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Only show scrollbars when scrolling
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Show the ~/Library folder
chflags nohidden ~/Library

# Restore boot sound on new macs
sudo nvram StartupMute=%00

# Check if brew is installed; if not, install brew
has_brew=`which brew 2>/dev/null`
if [[ -z $has_brew ]]
then
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew_taps_to_add=(
    'homebrew/cask'
)

for tap in "${brew_taps_to_add[@]}"; do
    brew tap $tap
done

brew update && brew upgrade

brew_packages_to_install=(
    'bash'
    'coreutils'
    'bash-completion'
    'tmux'
    'macvim'
    'mosh'
    'gnu-sed'
    'rsync'
    'thefuck'
    'tree'
    'glib'
    'colordiff'
    'mas'
    'nativefier'
    'jq'
    'findutils'
    'gnu-tar'
    'gnu-sed'
    'gawk'
    'gnutls'
    'gnu-indent'
    'oracle-jdk'
    'gnu-getopt'
    'grep'
    'wget'
    'zsh-autosuggestions'
    'pigz'
)

for package in "${brew_packages_to_install[@]}"; do
    has_package=`brew ls --versions $package`
    if [[ -z $has_package ]]; then
        brew install $package
    fi
done


brew_cask_to_install=(
    'iterm2'                # terminal
    'qlvideo'               # quicklook plugin for better viewo preview
    'suspicious-package'    # quicklook plugin to review the contents of a pkg
    'qlimagesize'           # quicklook plugin for showing img size
    'quicklook-json'        # quicklook plugin for json
    'quicklook-csv'         # quicklook plugin for csv
    'ttscoff-mmd-quicklook' # quicklook plugin for multimarkdown
    'qlmarkdown'            # quicklook plugin for markdown
    'qlstephen'             # quicklook plugin for plain text w/o extension
    'aerial'                # screen saver
    'keepingyouawake'       # prevent sleep
    'skim'                  # PDF viewer for latex
    'coconutbattery'        # check battery status
    'google-chrome'         # browser
    'appcleaner'            # good for app cleanup
    'slack'                 # chat app
    'spotify'               # music player
    'transmit'              # (s)ftp app
    'mactex'                # latex distribution for mac
    'alfred'                # launcher and clipboard manager
    'deckset'               # markdown presentations
    'coderunner'            # Lightweight IDE
    '1password'             # Password Manager
    'skype'                 # communication
    'visual-studio-code'    # text editor
    'istat-menus'           # menubar info
    'bartender'             # hide menu-bar icons
    'moom'					# window managment
    'lingon-x'              # manage startup items
    'jump'                  # remote desktop client
    'araxis-merge'          # diff tool
    'pdf-expert'            # edit pdfs
    'standard-notes'        # note taking app
    'geekbench'             # benchmarking
    'muse'                  # control spotify from touchbar + show status
    'sensiblesidebuttons'   # 3rd party mice
)

for cask in "${brew_cask_to_install[@]}"; do
    has_cask=$(brew cask list $cask 2>/dev/null)
    if [[ -z $has_cask ]]; then
        brew cask install $cask
    fi
done

mas_install=(
    '890031187'     # Marked 2
    '494803304'     # WiFi Explorer
    '497799835'     # Xcode
    '1289583905'    # Pixelmator Pro
    '969418666'     # ColorSnapper 2
    '429449079'     # Patterns
    '425424353'     # The Unarchiver
    '403304796'     # iNet Network Scanner
    '1191449274'    # ToothFairy
    '904280696'     # Things
)

not_signed_in_mas="Not signed in"

while [ ! -z "${not_signed_in_mas}" ]; do
    not_signed_in_mas=$(mas account | grep "Not signed in")

    if [ ! -z "${not_signed_in_mas}" ]; then
        echo "Please Sign in the Mac App Store and press return when done... "
        read foo
        continue
    fi

    for mas_app in "${mas_install[@]}"; do
        has_mas_app=$(mas list | grep $mas_app 2>/dev/null)
        if [[ -z $has_mas_app ]]; then
            mas install $mas_app
        fi
    done
done


# Install apps from github releases
github_install=(
    'Lord-Kamina/SwiftDefaultApps'
)
for gh_repo in "${github_install[@]}"; do
    # get release URL
    uri="$(curl https://api.github.com/repos/${gh_repo}/releases | jq -r '.[0].assets[0].browser_download_url')"

    # make a temp dir where to download stuff
    repo_dir="/tmp/$(echo ${gh_repo} | tr '/' '_')"
    mkdir -p ${repo_dir}

    # download the file
    gh_fn="$(basename ${uri})"
    gh_fp="${repo_dir}/${gh_fn}"
    wget ${uri} -O ${gh_fp}

    # check extension, decompress accordingly
    gh_ext="${gh_fn##*.}"

    if [ "${gh_ext}" == "gz" ] || [ "${gh_ext}" == "xz" ]; then
        tar -xf "${gh_fp}" -C "${repo_dir}"
    elif [ "${gh_ext}" == "zip" ]; then
        unzip ${gh_fp} -d "${repo_dir}"
    fi

    for app in $(ls --color=no "${repo_dir}"); do
        app_ext="${app##*.}"
        if [ "${app_ext}" == "app" ]; then
            cp -rf "${repo_dir}/${app}" "/Applications/"
            echo "Installed ${app}."
        fi
        if [ "${app_ext}" == "prefpane" ]; then
            cp -rf "${repo_dir}/${app}" "${HOME}/Library/PreferencePanes/"
            echo "Installed ${app}."
        fi
    done

    rm -rf ${repo_dir}

done

# configure sync folder iterm2
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "${HOME}/dotfiles/iterm2"

bash ${script_dir}/macos_import_prefs.sh

bash ${script_dir}/bootstrap.sh

echo "macOS setup completed."
