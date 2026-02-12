#!/usr/bin/env bash

# meta-keys are: @ Command, $ Shift, ~ Option, ^ Ctrl

# Global keyboard shortcuts
# from http://hints.macworld.com/article.php?story=20131123074223584
# and https://ryanmo.co/2017/01/05/setting-keyboard-shortcuts-from-terminal-in-macos/
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Paste and Match Style" "@~\$v"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Paste Special…" "@~\$v"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Save as PDF" "@p"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Save as PDF\\U2026" "@p"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Merge All Windows" "@u"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Show Help Menu" "~ "
defaults write -globalDomain NSUserKeyEquivalents -dict-add "Edit Tab Title" "@~^e"

# App keyboard shortcuts
defaults write com.apple.Safari NSUserKeyEquivalents -dict-add "Quit Safari" "@~q"
defaults write com.apple.Safari NSUserKeyEquivalents -dict-add "Quit and Keep Windows" "@q"
defaults write com.amazon.Amazon-Chime NSUserKeyEquivalents -dict-add "Hide Tab" "@\$w"
defaults write com.quip.Desktop NSUserKeyEquivalents -dict-add "Always Show Sidebar" "@~T"
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Archive" '@$A'

# Siri keyboard shortcut: disable trigger shortcut
defaults write com.apple.Siri HotkeyTag -int 4

# Disable mission control keyboard shortcuts while preserving other UI-edited entries.
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 32 "{enabled=0;}"
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 34 "{enabled=0;}"
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 38 "{enabled=0;}"
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 40 "{enabled=0;}"
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 44 "{enabled=0;}"
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 46 "{enabled=0;}"

# Disable input source switching shortcuts.
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 60 "{enabled=0;}"
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 61 "{enabled=0;}"

# Disable Finder search window shortcut (opt+cmd+space).
defaults write "com.apple.symbolichotkeys" "AppleSymbolicHotKeys" -dict-add 65 "{enabled=0;}"

# Window tiling shortcuts

## Fill: cmd+opt+shift+return
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Fill" "@~\$\\U21a9"

## Return to Previous Size: cmd+opt+shift+r
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Return to Previous Size" "@~$r"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Return to Previous Size" "@~$r"

## Halves: cmd+opt+shift+arrows
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Tile Left Half" "@~\$\\U2190"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Tile Right Half" "@~\$\\U2192"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Tile Top Half" "@~\$\\U2191"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Tile Bottom Half" "@~\$\\U2193"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Left" "@~\$\\U2190"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Right" "@~\$\\U2192"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Top" "@~\$\\U2191"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Bottom" "@~\$\\U2193"

## Quarters: cmd+opt+shift+h/l/j/k
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Tile Top Left Quarter" "@~\$h"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Tile Top Right Quarter" "@~\$l"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Tile Bottom Left Quarter" "@~\$j"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Tile Bottom Right Quarter" "@~\$k"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Top Left" "@~\$h"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Top Right" "@~\$l"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Bottom Left" "@~\$j"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Bottom Right" "@~\$k"

## Arrange actions should be unassigned ("none")
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Arrange Left and Right" ""
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Arrange Right and Left" ""
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Arrange Top and Bottom" ""
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Arrange Bottom and Top" ""
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Arrange in Quarters" ""
