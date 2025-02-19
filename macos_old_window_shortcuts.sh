#!/usr/bin/env bash

# Change tiling shortcut to work on external keyboard w/o fn key
## Fullscreen is ⌃⌥↩
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Fill" "~^\\U21a9"

## Return to Previous Size is ⌃⌥R
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Return to Previous Size" "~^r"

## Arranging to half size for left (⌃⌥←), right (⌃⌥→), top (⌃⌥↑), bottom (⌃⌥↓)
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Left" "~^\\U2190"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Right" "~^\\U2192"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Top" "~^\\U2191"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Bottom" "~^\\U2193"

## Arranging to quarters of the screen with top left (⌃⌥H), top right (⌃⌥L), bottom left (⌃⌥J), bottom right (⌃⌥K)
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Top Left" "~^h"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Top Right" "~^l"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Bottom Left" "~^j"
defaults write -globalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Bottom Right" "~^k"
