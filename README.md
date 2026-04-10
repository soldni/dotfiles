# dotfiles

Personal dotfiles and macOS workstation provisioning.

## Quick start

```bash
# Lightweight bootstrap: symlinks, shell config, utilities
./bootstrap.sh

# Full macOS provisioning (Homebrew, defaults, apps, shortcuts)
./macos_setup.sh [work|personal|server]
```

## What's here

- **Shell config** -- `.bashrc` (shared by bash/zsh), `.tmux.conf`, `.vimrc`
- **Editor/terminal settings** -- Ghostty, Zed, VS Code, Cursor, Sublime Text, iTerm2
- **macOS app preferences** -- backed up and restored via `plist_manager.sh` using `defaults export`/`import` (quits and relaunches apps automatically)
- **macOS defaults and shortcuts** -- `macos_setup.sh`, `macos_shortcuts.sh`
- **Utility scripts** -- `home-symlink/.local/scripts/`

## App preference sync

```bash
# Back up all tracked app preferences
./plist_manager.sh backup

# Restore all tracked app preferences
./plist_manager.sh restore
```

The script derives the app name from the preference domain, quits it before export/import, and relaunches afterward. Sensitive keys (license, email, etc.) are stripped automatically during backup.

See `AGENTS.md` for full details.
