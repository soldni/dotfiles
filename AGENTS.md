# AGENTS.md

Agent guide for this repository.

This repo is a personal dotfiles and workstation-provisioning repo. It is intentionally opinionated and contains machine-level scripts with broad side effects. Treat it as operations code, not as an app/library project.

## What this repo manages

- Shell and terminal behavior (`home-symlink/.bashrc`, `.zshrc`, `.tmux.conf`, `.vimrc`, terminal configs).
- App/editor settings (Ghostty, Zed, Cursor, Sublime Text, iTerm2, Alfred, rcmd).
- macOS defaults and full workstation bootstrap (`macos_setup.sh`).
- A small set of reusable templates (`templates/pyproject.toml`) and utility scripts (`home-symlink/.local/scripts`).

## Canonical install flow

### 1) Cross-platform bootstrap

Run `./bootstrap.sh`:

1. Creates `~/.prelocalrc` and `~/.postlocalrc` if missing.
2. Ensures `~/.ssh` exists.
3. Runs `home-symlink.sh` to mirror `home-symlink/` into `$HOME` as symlinks.
4. Downloads and installs `tsv-utils` into `~/.local/bin`.
5. Warns if `bc` is missing (tmux usage).

### 2) macOS full provisioning

Run `./macos_setup.sh` only when explicitly requested:

- Applies many macOS `defaults` writes and keyboard shortcut remaps.
- Runs `macos_shortcuts.sh`.
- Runs privileged commands (`sudo`, `nvram`), restarts system components, and installs Xcode CLT.
- Installs fonts from GitHub repos into system font locations.
- Installs/updates Homebrew formulae and casks, uninstalls some casks, installs MAS apps.
- Installs some apps from GitHub releases.
- Configures iTerm2 custom prefs path and scripts symlink.
- Symlinks `sublime-text/` into `~/Library/Application Support/Sublime Text`.
- Calls `./bootstrap.sh` near the end.

## High-risk scripts (read before running)

- `home-symlink.sh` is destructive by design:
  - For each managed file, it executes `rm -rf <destination>` before creating the symlink.
  - Running it can replace existing files/directories in the destination tree.
- `macos_setup.sh` has broad host side effects:
  - Changes OS defaults, installs/uninstalls software, uses `sudo`, and may prompt interactively (App Store sign-in, Xcode tools).

Do not run either script unless the user explicitly asks for machine changes.

## Repository map (what each top-level area is for)

- `home-symlink/`: source of truth for files linked into `$HOME`.
  - `home-symlink/.bashrc`: primary shell config (shared by bash and zsh).
  - `home-symlink/.zshrc` and `home-symlink/.bash_profile`: thin wrappers that source `.bashrc`.
  - `home-symlink/.agentsrc`: local shell helpers for agent tooling.
  - `home-symlink/.local/scripts/`: personal utility scripts (mixed quality/age; some legacy Python).
  - `home-symlink/.config/ghostty`, `home-symlink/.config/zed`: editor/terminal settings.
  - `home-symlink/Library/Application Support/com.nuebling.mac-mouse-fix/config.plist`: Mac Mouse Fix config.
- `macos_setup.sh`: full macOS provisioning workflow.
- `macos_no_animations.sh`: optional animation-reduction defaults.
- `macos_shortcuts.sh`: custom keyboard shortcuts.
- `bootstrap.sh`: lightweight setup + symlink bootstrap.
- `cursor/`: Cursor settings/keybindings/extensions snapshot.
- `sublime-text/`: Sublime `Installed Packages` and `Packages/User` synced by macOS setup.
- `defaults/sublime-text/`: default-file placeholders used by Sublime workflows.
- `iterm2/`, `iterm2-scripts/`: iTerm2 prefs and scripts linked by macOS setup.
- `rcmd/settings.json`: app switcher config.
- `Alfred.alfredpreferences/`: exported Alfred settings/workflows/snippets.
- `templates/pyproject.toml`: reusable Python project template.
- `home-symlink-backup/`: backup artifacts; not part of normal install flow.
- `.gitmodules`: declares optional `dotsecrets` submodule (may be absent in local checkout).

## Editing rules for agents

1. Edit the source, not the symlink target in `$HOME`.
2. Keep changes minimal and scoped to requested behavior.
3. Preserve cross-shell compatibility in `home-symlink/.bashrc` (it is used by bash and zsh).
4. Do not mass-format or normalize large exported trees (`Alfred.alfredpreferences/`, plist-heavy dirs) unless explicitly requested.
5. Be careful with secrets and host-specific values:
   - This repo contains personal identifiers and host-specific config.
   - Keep machine-local overrides in `~/.prelocalrc` / `~/.postlocalrc` (created by bootstrap, not stored in repo).
6. Preserve executable bits for scripts where applicable.
7. Note legacy compatibility:
   - `home-symlink/.local/scripts/diceware.py` targets Python 2.
   - `home-symlink/.local/scripts/chrome-to-firefox.scpt` is a compiled AppleScript/binary file.

## Validation checklist after edits

Run relevant checks based on changed files:

```bash
# Shell scripts
bash -n bootstrap.sh home-symlink.sh macos_setup.sh macos_no_animations.sh macos_shortcuts.sh

# JSON files (example)
jq . cursor/settings.json >/dev/null

# plist files (example)
plutil -lint "home-symlink/Library/Application Support/com.nuebling.mac-mouse-fix/config.plist"
```

If a change affects symlink-managed files, apply with care:

```bash
# Re-link all managed home files (destructive to existing targets)
./home-symlink.sh
```

## Profiling `.bashrc` startup

Use this workflow when shell startup feels slow.

1. Measure startup time of just this repo's bashrc:

```bash
time bash --noprofile --norc -i -c 'source /Users/lucas/dotfiles/home-symlink/.bashrc; exit'
```

2. Capture a line-level execution trace with timestamps:

```bash
TRACE_FILE=/tmp/bashrc_trace.$$.log
bash --noprofile --norc -i -c 'export PS4="+${EPOCHREALTIME}\t${BASH_SOURCE}:${LINENO}: "; exec 3>"'"$TRACE_FILE"'"; BASH_XTRACEFD=3; set -x; source /Users/lucas/dotfiles/home-symlink/.bashrc; set +x'
echo "$TRACE_FILE"
```

3. Rank hotspots (largest gaps between traced commands first):

```bash
awk 'BEGIN{prev_ts=0;prev_line=""} /^\++[0-9]+\.[0-9]+/{line=$0; sub(/^\++/,"",line); ts=substr(line,1,17)+0; if(prev_ts>0){d=ts-prev_ts; if(d>0.02) printf "%.3fs | %s\n", d, prev_line} prev_ts=ts; prev_line=$0 }' "$TRACE_FILE" | sort -nr | head -n 30
```

4. Re-check with multiple runs after edits:

```bash
for i in 1 2 3 4 5; do /usr/bin/time -p bash --noprofile --norc -i -c 'source /Users/lucas/dotfiles/home-symlink/.bashrc; exit' >/dev/null; done
```

Notes:
- `home-symlink/.bashrc` sources `~/.prelocalrc` and `~/.postlocalrc`; slow network/CLI calls there often dominate startup.
- In non-interactive/CI-like environments, warnings from `stty`, `ps`, or `ssh-agent` can appear and are not always real interactive-shell regressions.
- Prefer lazy-loading for expensive commands (`brew`, cloud CLIs, token fetches) during startup.

## Common task routing

- Shell prompt/aliases/env/path changes:
  - edit `home-symlink/.bashrc`.
- Zsh-only startup behavior:
  - usually still goes through `home-symlink/.bashrc`; keep `home-symlink/.zshrc` minimal.
- macOS shortcut/defaults tweaks:
  - edit `macos_shortcuts.sh` and/or `macos_setup.sh`.
- Ghostty/Zed/Cursor/Sublime app config updates:
  - edit under their respective directories in this repo, then re-link/import as needed.

## Non-goals

- Do not treat this repository as a package with unit/integration tests.
- Do not assume scripts are idempotent or safe for unattended CI execution.
