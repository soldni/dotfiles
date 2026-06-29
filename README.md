<p align="center">
  <img src="logo.png" alt="dotfiles logo" width="300">
</p>

# dotfiles

Personal dotfiles and macOS workstation provisioning.

## Quick start

```bash
# Lightweight bootstrap: symlinks, shell config, utilities
./bootstrap.sh

# Full macOS provisioning (Homebrew, defaults, apps, shortcuts)
./macos_setup.sh [work|personal|server]
```

## Repo-local GitHub SSH override

This repo's remote is `git@github.com:soldni/dotfiles.git`, but on this machine the global `~/.ssh/config` can inject the wrong identity via a broad `Host *` stanza. Setting only `-i ~/.ssh/personal` is not enough, because SSH still reads the global config and may offer another key first.

If `git push` starts authenticating as the wrong GitHub account, set a repo-local SSH command that ignores global SSH config entirely:

```bash
git config core.sshCommand 'ssh -F /dev/null -i ~/.ssh/personal -o IdentitiesOnly=yes'
```

Why this works:

- `-F /dev/null` tells `ssh` not to read `~/.ssh/config`.
- `-i ~/.ssh/personal` pins the key for this repo.
- `-o IdentitiesOnly=yes` prevents `ssh` from offering extra identities from the agent or config.

Verify it with:

```bash
GIT_TRACE=1 git push --dry-run origin HEAD
```

You should see Git invoke `ssh -F /dev/null -i ~/.ssh/personal -o IdentitiesOnly=yes ...` and the dry run should succeed.

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
