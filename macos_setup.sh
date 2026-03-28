#!/usr/bin/env bash

profile="${1:-work}"
profile="$(printf '%s' "${profile}" | tr '[:upper:]' '[:lower:]')"
is_personal_like="false"
run_no_animations="false"
is_work_like="true"

case "${profile}" in
    personal)
        is_personal_like="true"
        is_work_like="false"
        ;;
    server)
        is_personal_like="true"
        run_no_animations="true"
        is_work_like="false"
        ;;
    work)
        ;;
    *)
        echo "Usage: $0 [personal|work|server]" >&2
        exit 1
        ;;
esac

# notifying user which kind of setup is being applied
echo "Applying ${profile} setup..."

# This is a host-level provisioning script. It intentionally mutates macOS
# defaults, installs software, and runs some interactive commands.
set -eoux pipefail

warned_container_domains=""

# Some app domains resolve to sandbox container plists on current macOS
# versions. Those can reject command-line writes even when the owning app is
# installed, so warn once and keep applying the rest of the setup.
note_unwritable_container_domain() {
    local domain="$1"

    case ",${warned_container_domains}," in
        *,"${domain}",*)
            return 0
            ;;
    esac

    printf 'Skipping defaults writes for %s: macOS blocked CLI access to that app container preference domain.\n' "$domain" >&2
    warned_container_domains="${warned_container_domains},${domain}"
}

# Wrapper around `defaults write` that treats container-domain failures as a
# best-effort skip while still failing on unexpected errors.
write_defaults() {
    local domain="$1"
    shift

    local output
    if ! output=$(defaults write "$domain" "$@" 2>&1); then
        if [[ "$output" == *"Could not write domain "*"/Library/Containers/"* ]]; then
            note_unwritable_container_domain "$domain"
            return 0
        fi

        printf '%s\n' "$output" >&2
        return 1
    fi
}

list_contains() {
    local list="$1"
    local item="$2"

    [[ -n "$list" ]] || return 1
    grep -Fqx -- "$item" <<< "$list"
}

#
# Small helpers for building batched brew/mas command lines without duplicate
# entries from the configured package lists below.
array_contains() {
    local item="$1"
    shift

    local existing
    for existing in "$@"; do
        if [[ "$existing" == "$item" ]]; then
            return 0
        fi
    done
    return 1
}

# `xcode-select --install` is awkward to automate: it prints one message when
# an install was requested, another when CLT is already present, and may still
# return a non-zero exit status. Normalize those cases here.
ensure_xcode_command_line_tools() {
    local install_requested_msg='xcode-select: note: install requested for command line developer tools'
    local already_installed_msg='xcode-select: note: Command line tools are already installed. Use "Software Update" in System Settings or the softwareupdate command line interface to install updates'
    local sleep_timeout=30
    local output

    output="$(xcode-select --install 2>&1 || true)"

    case "$output" in
        "$install_requested_msg")
            while ! xcode-select -p >/dev/null 2>&1; do
                echo "xcode-select not completed, waiting ${sleep_timeout} s before checking again..."
                sleep "${sleep_timeout}"
            done
            ;;
        "$already_installed_msg")
            echo "xcode-select reports command line tools are already installed; continuing."
            ;;
        "")
            if ! xcode-select -p >/dev/null 2>&1; then
                echo "xcode-select --install produced no output and command line tools are not configured." >&2
                return 1
            fi
            ;;
        *)
            printf '%s\n' "$output" >&2
            return 1
            ;;
    esac
}

# location of this script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Apply the separate shortcut script first so menu and symbolic hotkeys are in
# place before the rest of the workstation setup.
bash ${script_dir}/macos_shortcuts.sh

# Adjust Siri settings
defaults write com.apple.Siri TypeToSiriEnabled -bool true
defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri LockscreenEnabled -bool false

# Spaces sensible defaults
defaults write "com.apple.spaces" "spans-displays" -int 0
defaults write "com.apple.dock" "mru-spaces" -int 0
defaults write "Apple Global Domain" "AppleSpacesSwitchOnActivate" -int 0

# Mission control settings
defaults write "com.apple.dock" "expose-group-apps" -int 1

# Tiling settings
defaults write "com.apple.WindowManager" "EnableTilingByEdgeDrag" -int 0
defaults write "com.apple.WindowManager" "EnableTopTilingByEdgeDrag" -int 0
defaults write "com.apple.WindowManager" "EnableTilingOptionAccelerator" -int 0
defaults write "com.apple.WindowManager" "EnableTiledWindowMargins" -int 0

# Local connections only for VNC
sudo defaults write /Library/Preferences/com.apple.RemoteManagement.plist VNCOnlyLocalConnections -bool yes

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false
defaults write -g AppleSpacesSwitchOnActivate -bool false

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
defaults write com.apple.dock size-immutable -bool yes
defaults write com.apple.dock contents-immutable -bool yes
defaults write com.apple.dock showAppExposeGestureEnabled -bool true
defaults write com.apple.dock showMissionControlGestureEnabled -bool true
defaults write "com.apple.dock" "show-process-indicators" -int 0
defaults write "com.apple.dock" "show-recents" -int 0
killall Dock

# Disable sound for alerts
defaults write "Apple Global Domain" "com.apple.sound.beep.volume" -int 0

# FN button shows emoji menu
defaults write "com.apple.HIToolbox" "AppleFnUsageType" -int 2

# No sound for UI
defaults write "Apple Global Domain" "com.apple.sound.uiaudio.enabled" -int 0

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
write_defaults com.apple.Safari HomePage -string "about:blank"
write_defaults com.apple.Safari AutoOpenSafeDownloads -bool false
write_defaults com.apple.Safari ShowFavoritesBar -bool true
write_defaults com.apple.Safari ShowSidebarInTopSites -bool false
write_defaults com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
write_defaults com.apple.Safari IncludeDevelopMenu -bool true
write_defaults com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
write_defaults com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
write_defaults com.apple.Safari AutoFillFromAddressBook -bool false
write_defaults com.apple.Safari AutoFillPasswords -bool false
write_defaults com.apple.Safari AutoFillCreditCardData -bool false
write_defaults com.apple.Safari AutoFillMiscellaneousForms -bool false
write_defaults com.apple.Safari SendDoNotTrackHTTPHeader -bool true
write_defaults com.apple.Safari NewTabBehavior -int 1
write_defaults com.apple.Safari NewWindowBehavior -int 1
write_defaults com.apple.Safari ShowIconsInTabs -int 1

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Remove all apps from dock
defaults write com.apple.dock persistent-apps -array

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
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleActionOnDoubleClick -string "Minimize"
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
defaults write NSGlobalDomain AppleAquaColorVariant -int 1

# start on monday
defaults write NSGlobalDomain AppleFirstWeekday '{gregorian = 2;}'
defaults write AppleICUDateFormatStrings '{1 = "y-MM-dd";}'
defaults write AppleICUForce24HourTime -bool true

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
ensure_xcode_command_line_tools


# Bootstrap Homebrew if needed before using the managed formula/cask lists.
has_brew=`which brew 2>/dev/null`
if [[ -z $has_brew ]]
then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew_taps_to_add=(
    'jlhonora/lsusb'
    'erictli/tap'   # for notes app
    # 'homebrew/cask-fonts'     # deprecated
    # 'homebrew/cask'           # no longer needed
)

for tap in "${brew_taps_to_add[@]}"; do
    brew tap $tap
done

# Upgrade everything Homebrew already knows about. The managed install lists
# below are then only responsible for adding missing packages/casks.
brew update && brew upgrade

brew_packages_to_install=(
    'bash-completion'
    'bash'
    'blueutil'
    'colordiff'
    'coreutils'
    'diff-pdf'
    'findutils'
    'fswatch'
    'gawk'
    'gcc'
    'gh'
    'glib'
    'gnu-getopt'
    'gnu-indent'
    'gnu-sed'
    'gnu-sed'
    'gnu-tar'
    'gnutls'
    'grep'
    'jq'
    'lsusb'
    'macvim'
    'mas'
    'mosh'
    'node'
    'npm'
    'openblas'
    'pigz'
    'pipx'
    'python'
    'reattach-to-user-namespace'
    'ripgrep'
    'rsync'
    'speedtest-cli'
    'tmux'
    'tree'
    'uv'
    'wget'
    'xz'
    'zsh-autosuggestions'
    'zstd'
)

# set default install location for node
npm config set prefix "${HOME}/.local"


# Install missing formulae in one brew invocation to reduce repeated brew
# startup overhead. Already-installed formulae were handled by `brew upgrade`.
installed_formulae="$(brew list --formula)"
brew_packages_missing=()
for package in "${brew_packages_to_install[@]}"; do
    if ! list_contains "$installed_formulae" "$package" && ! array_contains "$package" "${brew_packages_missing[@]}"; then
        brew_packages_missing+=("$package")
    fi
done
if [[ ${#brew_packages_missing[@]} -gt 0 ]]; then
    brew install "${brew_packages_missing[@]}"
fi


# these are apps I don't use anymore
# we uninstall them first and then do a cleanup
brew_cask_to_uninstall=(
    'cyberduck'             # sftp client
    'fantastical'           # calendar
    'firefox@beta'          # browser
    'lingon-x'              # manage startup items
    'monitorcontrol'        # control external monitor settings
    'orion'                 # browser
    'readdle-spark'         # email client
    'spotify'               # music player
    'vanilla'               # hide menubar icons
    'cursor'                # text editor
    'transmit'              # sftp client
    'zed'                   # text editor
    'obsidian'              # note taking
    'mimestream'            # email client
    'zoom'                  # video conferencing
)

# Only uninstall casks that are currently present, then batch them into a
# single `brew uninstall --cask` call.
installed_casks="$(brew list --cask)"
brew_casks_present_to_uninstall=()
for cask in "${brew_cask_to_uninstall[@]}"; do
    if list_contains "$installed_casks" "$cask" && ! array_contains "$cask" "${brew_casks_present_to_uninstall[@]}"; then
        brew_casks_present_to_uninstall+=("$cask")
    fi
done
if [[ ${#brew_casks_present_to_uninstall[@]} -gt 0 ]]; then
    brew uninstall --force --cask "${brew_casks_present_to_uninstall[@]}"
fi

# do the cleanup
brew cleanup

brew_cask_to_install=(
    'maccy'                 # clipboard manager
    '1password'             # Password Manager
    'appcleaner'            # good for app cleanup
    'claude-code'           # Anthropic CLI coding agent
    'codex'                 # OpenAI CLI coding agent
    'visual-studio-code'    # text editor
    'discord'               # chat app
    'ghostty'               # terminal
    'github'                # git client
    'imageoptim'            # image optimization
    'keepingyouawake'       # prevent sleep
    'mac-mouse-fix'         # additonal mouse settings
    'macvim'                # vim
    'sketch'                # vector design
    'slack'                 # chat app
)

if [[ "${is_personal_like}" == "true" ]]; then
    brew_cask_to_install+=(
        'netnewswire'           # rss reader
        'signal'                # encrypted chat
        'orbstack'              # replacement for docker
        'codex-app'             # OpenAI Desktop coding app
        'claude'                # Anthropic desktop app
        'chatgpt'               # OpenAI desktop app
    )
fi

if [[ "${is_work_like}" == "true" ]]; then
    brew_cask_to_install+=(
        'erictli/tap/scratch'
    )
fi

fonts_to_install=(
    'font-fira-code'
    'font-iosevka'
    'font-iosevka-curly'
    'font-iosevka-curly-slab'
    'font-iosevka-etoile'
    'font-iosevka-nerd-font'
    'font-iosevka-term-nerd-font'
    'font-iosevka-slab'
    'font-iosevka-term-slab-nerd-font'
    'font-aporetic'
    'font-manrope'
    'font-mona-sans'
    'font-monaspace'
    'font-monaspice-nerd-font'
    'font-atkinson-hyperlegible'
    'font-atkinson-hyperlegible-next'
    'font-atkinson-hyperlegible-mono'
    'font-fira-code'
    'font-fira-code-nerd-font'
    'font-fira-mono'
    'font-fira-mono-for-powerline'
    'font-fira-mono-nerd-font'
    'font-fira-sans'
    'font-fira-sans-condensed'
    'font-fira-sans-extra-condensed'
)
brew_cask_to_install+=("${fonts_to_install[@]}")

# Batch missing casks and fonts into one install call. Duplicate entries in the
# configured lists are filtered out before invoking brew.
installed_casks="$(brew list --cask)"
brew_casks_missing=()
for package in "${brew_cask_to_install[@]}"; do
    if ! list_contains "$installed_casks" "$package" && ! array_contains "$package" "${brew_casks_missing[@]}"; then
        brew_casks_missing+=("$package")
    fi
done
if [[ ${#brew_casks_missing[@]} -gt 0 ]]; then
    brew install --cask --force "${brew_casks_missing[@]}"
fi

if [[ "${is_personal_like}" == "true" ]]; then
    # `server` inherits the personal app set; `work` skips App Store work.
    mas_install=(
        '1662217862'    # Wipr2                      (2.0)
        '6471380298'    # StopTheMadnessPro          (11.1)
        '1502111349'    # PDF Squeezer               (4.5.3)
        '1508732804'    # Soulver 3                  (3.11.2)
        '1545870783'    # Color Picker               (2.0.1)
        '1569813296'    # 1Password for Safari       (2.24.2)
        '1592917505'    # Noir                       (2024.2.1)
        '1622835804'    # com.kagimacOS.Kagi-Search  (2.2.3)
        '429449079'     # Patterns                   (1.3)
        '497799835'     # Xcode                      (15.4)
        '899247664'     # TestFlight                 (3.5.1)
        '992115977'     # Image2icon                 (2.18)
        '6468265473'    # Upscayl                    (2.15.0)
    )

    # older apps
    # '1475387142'    # Tailscale                  (1.68.1)
    # '6475380719'    # Picture in Picture         (1.0.0)
    # '403304796'     # iNet Network Scanner       (3.1.1)
    # '425424353'     # The Unarchiver             (4.3.8)

    # `mas install` requires an active App Store session. Keep prompting until
    # the user signs in, then install all missing app IDs in one command.
    while [[ "$(mas account 2>&1 || true)" == *"Not signed in"* ]]; do
        echo "Please sign in to the Mac App Store and press return when done..."
        read -r _
    done

    installed_mas_apps="$(mas list | awk '{print $1}')"
    mas_apps_missing=()
    for mas_app in "${mas_install[@]}"; do
        if ! list_contains "$installed_mas_apps" "$mas_app" && ! array_contains "$mas_app" "${mas_apps_missing[@]}"; then
            mas_apps_missing+=("$mas_app")
        fi
    done
    if [[ ${#mas_apps_missing[@]} -gt 0 ]]; then
        mas install "${mas_apps_missing[@]}"
    fi
fi


# Install a small set of apps distributed outside Homebrew/App Store by pulling
# the newest GitHub release asset and copying app bundles into place.
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

bash ${script_dir}/bootstrap.sh

# clean up brew
brew cleanup

# clean up npm
npm cache clean --force

# purge uv cache
uv cache clean

if [[ "${run_no_animations}" == "true" ]]; then
    # The `server` profile is the personal setup plus animation-reduction
    # defaults applied as a final pass.
    bash "${script_dir}/macos_no_animations.sh"
fi

echo "macOS setup completed."
