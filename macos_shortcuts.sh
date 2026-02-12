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

# Disable symbolic hotkeys by setting enabled=false, preserving the value sub-dict.
SH_PLIST=~/Library/Preferences/com.apple.symbolichotkeys.plist

# Mission control shortcuts.
for key in 32 34 38 40 44 46; do
  /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${key}:enabled false" "$SH_PLIST"
done

# Input source switching shortcuts.
for key in 60 61; do
  /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${key}:enabled false" "$SH_PLIST"
done

# Finder search window shortcut (opt+cmd+space).
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:65:enabled false" "$SH_PLIST"

# Window tiling shortcuts

## Fill: cmd+opt+shift+return
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Fill" "@~\$\\U21a9"

## Center: cmd+opt+shift+c
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Center" "@~\$c"

## Return to Previous Size: cmd+opt+shift+r
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Return to Previous Size" "@~\$r"

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

## Disable Arrange actions (symbolic hotkeys, not menu shortcuts).
for key in 248 249 250 251 256; do
  /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${key}:enabled false" "$SH_PLIST"
done
