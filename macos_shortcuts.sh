#!/usr/bin/env bash

set -euo pipefail

# Configure menu shortcuts via NSUserKeyEquivalents and lower-level system
# shortcuts via AppleSymbolicHotKeys. Newer macOS releases block some
# app-container preference domains from plain shell processes, so app-specific
# writes are best-effort instead of fatal.

# meta-keys are: @ Command, $ Shift, ~ Option, ^ Ctrl

warned_container_domains=""

# Some Apple apps store preferences in sandbox containers and reject
# `defaults write` from an unsandboxed shell. Warn once per domain and keep
# applying the rest of the shortcut set.
note_unwritable_container_domain() {
  local domain="$1"

  case ",${warned_container_domains}," in
    *,"${domain}",*)
      return 0
      ;;
  esac

  printf 'Skipping app shortcut writes for %s: macOS blocked CLI access to that app container preference domain.\n' "$domain" >&2
  warned_container_domains="${warned_container_domains},${domain}"
}

# NSUserKeyEquivalents targets literal menu titles. This helper centralizes the
# container-domain handling for app-specific menu shortcuts.
write_app_shortcut() {
  local domain="$1"
  local menu_item="$2"
  local shortcut="$3"
  local output

  if ! output=$(defaults write "$domain" NSUserKeyEquivalents -dict-add "$menu_item" "$shortcut" 2>&1); then
    if [[ "$output" == *"Could not write domain "*"/Library/Containers/"* ]]; then
      note_unwritable_container_domain "$domain"
      return 0
    fi

    printf '%s\n' "$output" >&2
    return 1
  fi
}

# AppleSymbolicHotKeys entries vary by OS version, hardware, and which features
# have ever been enabled. Skip missing keys and rewrite `enabled` as a bool so
# older runs do not leave behind string values.
disable_symbolic_hotkey() {
  local key="$1"

  if [[ ! -f "$SH_PLIST" ]]; then
    return 0
  fi

  if ! /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:${key}" "$SH_PLIST" >/dev/null 2>&1; then
    return 0
  fi

  # Re-add the key as a bool so older runs do not leave behind string values.
  /usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:${key}:enabled" "$SH_PLIST" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:enabled bool false" "$SH_PLIST" >/dev/null
}

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
write_app_shortcut com.apple.Safari "Quit Safari" "@~q"
write_app_shortcut com.apple.Safari "Quit and Keep Windows" "@q"
write_app_shortcut com.amazon.Amazon-Chime "Hide Tab" "@\$w"
write_app_shortcut com.quip.Desktop "Always Show Sidebar" "@~T"
write_app_shortcut com.apple.mail "Archive" '@$A'
write_app_shortcut com.microsoft.onenote.mac "Format->Styles->Code" "@~\$k"

# Siri keyboard shortcut: disable trigger shortcut
defaults write com.apple.Siri HotkeyTag -int 4

# Disable symbolic hotkeys by setting enabled=false, preserving the value sub-dict.
SH_PLIST=~/Library/Preferences/com.apple.symbolichotkeys.plist

# Mission control shortcuts.
for key in 32 34 38 40 44 46; do
  disable_symbolic_hotkey "$key"
done

# Input source switching shortcuts.
for key in 60 61; do
  disable_symbolic_hotkey "$key"
done

# Finder search window shortcut (opt+cmd+space).
disable_symbolic_hotkey 65

# Window tiling shortcuts
# Nested menu items use ESC-delimited menu paths in NSUserKeyEquivalents,
# e.g. "Window > Move & Resize > Left".

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
  disable_symbolic_hotkey "$key"
done
