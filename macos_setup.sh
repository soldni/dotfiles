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

# Make CMD+Q keep window, CMD+ALT+Q not
defaults write com.apple.Safari NSUserKeyEquivalents -dict-add "Quit Safari" "@~q"
defaults write com.apple.Safari NSUserKeyEquivalents -dict-add "Quit and Keep Windows" "@q"

# Adjust Siri settings
defaults write com.apple.Siri TypeToSiriEnabled -bool true
defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri LockscreenEnabled -bool false
defaults write com.apple.Siri HotkeyTag -int 4

# Local connections only for VNC
sudo defaults write /Library/Preferences/com.apple.RemoteManagement.plist VNCOnlyLocalConnections -bool yes

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
defaults write com.apple.dock autohide-time-modifier -float 0.05
defaults write com.apple.dock mouse-over-hilite-stack -bool true
defaults write com.apple.dock persistent-apps -array
killall Dock

# Save screenshots to Downloads
defaults write com.apple.screencapture location "${HOME}/Downloads"

# Setup Finder
defaults write com.apple.finder CreateDesktop false
killall Finder

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

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

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Finder settings
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# Safari
defaults write com.apple.Safari HomePage -string "about:blank"
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
defaults write com.apple.Safari ShowFavoritesBar -bool true
defaults write com.apple.Safari ShowSidebarInTopSites -bool false
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write com.apple.Safari AutoFillFromAddressBook -bool false
defaults write com.apple.Safari AutoFillPasswords -bool false
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
defaults write com.apple.Safari NewTabBehavior -int 1
defaults write com.apple.Safari NewWindowBehavior -int 1
defaults write com.apple.Safari ShowIconsInTabs -int 1

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0
# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Colors and interface
defaults write NSGlobalDomain AppleHighlightColor -string "0.968627 0.831373 1.000000 Purple"
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleActionOnDoubleClick -string "Minimize"
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
defaults write NSGlobalDomain AppleAquaColorVariant -int 1

# Customize trackpad to my liking
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFiveFingerPinchGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad DragLock -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false

# Do not create .DS_Store files on remote disks or USB stores
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Only show scrollbars when scrolling
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# PasteBot hide menubar and dock
defaults write com.tapbots.Pastebot2Mac UIVisibilityState 10

# Show the ~/Library folder
chflags nohidden ~/Library

# Restart SystemUIServer
killall SystemUIServer

# Restore boot sound on new macs
sudo nvram StartupMute=%00

# Gotta install xcode optional tools
xcode-select --install

# Waiting for xcode tools to be installed; adapted from here:
#   https://stackoverflow.com/a/35005051
check="$($(xcode-\select --install) 2>&1)"
checkOut="xcode-select: note: install requested for command line developer tools"
sleep_timeout=30
while [[ "$check" == "$checkOut" ]];
do
  echo "xcode-select not completed, waiting ${sleep_timeout} s before checking again..."
  sleep ${sleep_timeout}
  check="$($(xcode-\select --install) 2>&1)"
  checkOut="xcode-select: note: install requested for command line developer tools"
done

# install powerline fonts
current_dir="$(pwd)"
cd "${HOME}/Downloads"
git clone https://github.com/powerline/fonts.git
cd fonts
bash install.sh
cd ..
rm -rf fonts
cd "${current_dir}"

# install Monaspace fonts
current_dir="$(pwd)"
cd "${HOME}/Downloads"
git clone https://github.com/githubnext/monaspace.git
cd monaspace
bash ./util/install_macos.sh
cd ..
rm -rf monaspace
cd "${current_dir}"

# Check if brew is installed; if not, install brew
has_brew=`which brew 2>/dev/null`
if [[ -z $has_brew ]]
then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew_taps_to_add=(
    'homebrew/cask'
    'jlhonora/lsusb'
    'homebrew/cask-fonts'
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
    'homebrew/cask/macvim'
    'mosh'
    'blueutil'
    'gnu-sed'
    'rsync'
    'tree'
    'glib'
    'colordiff'
    'mas'
    'nativefier'
    'jq'
    'findutils'
    'openblas'
    'gnu-tar'
    'gnu-sed'
    'gawk'
    'gnutls'
    'gnu-indent'
    'gnu-getopt'
    'grep'
    'fswatch'
    'wget'
    'zsh-autosuggestions'
    'pigz'
    'lsusb'
    'diff-pdf'
    'ripgrep'
)


for package in "${brew_packages_to_install[@]}"; do
    has_package=$(brew list ${package} 2>/dev/null)
    if [[ -z $has_package ]]; then
        brew install $package
    else
        brew upgrade $package
    fi
done


brew_cask_to_install=(
    'iterm2'                # terminal
    'keepingyouawake'       # prevent sleep
    'appcleaner'            # good for app cleanup
    'slack'                 # chat app
    'spotify'               # music player
    'transmit'              # (s)ftp app
    'alfred'                # launcher and clipboard manager
    'sketch'                # vector design
    '1password'             # Password Manager
    'visual-studio-code'    # text editor
    'mimestream'            # email client
    # 'lingon-x'              # manage startup items
    'vlc'                   # player
    'monitorcontrol'        # control external monitor setttings
    'font-fira-code'        # font with ligatures
    'sublime-text'          # text editor; faster than vscode
    'signal'                # encrypted chat
    'notion'                # note taking
)


for package in "${brew_cask_to_install[@]}"; do
    has_package=$(brew list ${package} 2>/dev/null)
    if [[ -z $has_package ]]; then
        brew install --cask $package
    else
        brew upgrade $package
    fi
done

mas_install=(
    '429449079'     # Patterns
    '425424353'     # The Unarchiver
    '403304796'     # iNet Network Scanner
    '956377119'     # WorldClock
    '1289583905'    # Pixelmator Pro
    '1592917505'    # Noir
    '992115977'     # image2icon
    '1569813296'    # 1Password For Safari
    '1320666476'    # Wipr
    '2143935391'    # OpenCat
    '1502111349'    # PDF Squeezer
    # '1475387142'    # TailScale
    '1376402589'    # Stop The Maddenss
    '1179623856'    # Pastebot
    '441258766'     # Magnet
    '1545870783'    # Color Picker
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


function install_from_repo () {
    github_repo_name="${1}"

    # get release URL
    uri="$(curl https://api.github.com/repos/${github_repo_name}/releases | jq -r '.[0].assets[0].browser_download_url')"

    # make a temp dir where to download stuff
    repo_dir="/tmp/$(echo ${github_repo_name} | tr '/' '_')"
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
}

# Install apps from github releases
github_install=(
    'Lord-Kamina/SwiftDefaultApps'
    'pallotron/yubiswitch'
)
for gh in "${github_install[@]}"; do
    install_from_repo "${gh}"
done

# configure sync folder iterm2 & symlink scripts
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "${HOME}/dotfiles/iterm2"
rm -rf "${HOME}/Library/Application Support/iTerm2/Scripts"
ln -s ${script_dir}/iterm2-scripts "${HOME}/Library/Application Support/iTerm2/Scripts"

# configure symlink for sublime text
bash ${script_dir}/home-symlink.sh \
    "${script_dir}/sublime-text" \
    "${HOME}/Library/Application Support/Sublime Text" \
    0

bash ${script_dir}/bootstrap.sh

echo "macOS setup completed."
