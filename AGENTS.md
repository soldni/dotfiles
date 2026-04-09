# AGENTS.md

Agent guide for this repository.

This repo is a personal dotfiles and workstation-provisioning repo. It is intentionally opinionated and contains machine-level scripts with broad side effects. Treat it as operations code, not as an app/library project.

## What this repo manages

- Shell and terminal behavior (`home-symlink/.bashrc`, `.zshrc`, `.tmux.conf`, `.vimrc`, terminal configs).
- App/editor settings (Ghostty, Zed, VS Code, Cursor, Sublime Text, iTerm2, Alfred, rcmd).
- macOS app preferences via plist backup/restore (`plist_manager.sh`, `plists/`).
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

- Profiles:
  - `work`: baseline workstation setup.
  - `personal`: `work` plus personal casks and MAS apps.
  - `server`: equivalent to `personal`, then runs `macos_no_animations.sh` as a final pass.
- Applies many macOS `defaults` writes and keyboard shortcut remaps.
- Runs `macos_shortcuts.sh`.
- Runs privileged commands (`sudo`, `nvram`), restarts system components, and installs Xcode CLT.
- Installs/updates Homebrew formulae and casks, uninstalls some casks, installs MAS apps.
- Installs some apps from GitHub releases.
- Calls `./bootstrap.sh` near the end.
- Restores tracked app preference plists via `plist_manager.sh restore`.

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
  - `home-symlink/Library/Application Support/Code/User/`: VS Code settings, keybindings, extensions list.
  - `home-symlink/Library/Application Support/Cursor/User/`: Cursor settings, keybindings, extensions list.
  - `home-symlink/Library/Application Support/com.nuebling.mac-mouse-fix/config.plist`: Mac Mouse Fix config (symlinked directly; this app reads its config file, not a preferences domain).
- `plist_manager.sh`: backup and restore macOS preference-domain plists as human-readable XML.
- `plists/`: versioned XML backups of tracked app preference domains (e.g. `com.manytricks.Moom.xml`). Managed by `plist_manager.sh`; never edit these files by hand.
- `macos_setup.sh`: full macOS provisioning workflow.
- `macos_no_animations.sh`: optional animation-reduction defaults.
- `macos_shortcuts.sh`: custom keyboard shortcuts.
- `bootstrap.sh`: lightweight setup + symlink bootstrap.
- `ide_extensions.sh`: IDE extension installer script.
- `cursor/`: Cursor settings/keybindings/extensions snapshot.
- `sublime-text/`: Sublime `Installed Packages` and `Packages/User`.
- `defaults/sublime-text/`: default-file placeholders used by Sublime workflows.
- `iterm2/`: iTerm2 preferences plist.
- `rcmd/settings.json`: app switcher config.
- `Alfred.alfredpreferences/`: exported Alfred settings/workflows/snippets.
- `templates/pyproject.toml`: reusable Python project template.

## App preference plist management

macOS apps store their preferences as plist files in `~/Library/Preferences/`. Symlink-based approaches do not work for these because `cfprefsd` ignores symlinks, and apps overwrite the file on every settings change.

Instead, this repo uses `plist_manager.sh` to export/import preference domains via `defaults export`/`defaults import` and stores the results as human-readable XML in `plists/`.

### Backing up preferences

```bash
# Back up all tracked domains
./plist_manager.sh backup

# Back up a single domain
./plist_manager.sh backup com.manytricks.Moom
```

During backup, the script automatically strips:
- **Top-level keys** matching sensitive patterns: `license`, `serial`, `registration`, `email`, `NSWindow Frame *`.

### Restoring preferences

```bash
# Restore all tracked domains
./plist_manager.sh restore

# Restore a single domain
./plist_manager.sh restore com.manytricks.Moom
```

`macos_setup.sh` calls `plist_manager.sh restore` automatically after apps are installed.

### Adding a new tracked domain

1. Add the domain string to the `TRACKED_DOMAINS` array in `plist_manager.sh`.
2. Run `./plist_manager.sh backup <domain>` to create the initial XML.
3. Review the generated file in `plists/` for any PII or secrets that slipped through — add new patterns to `SENSITIVE_TOP_LEVEL_PATTERNS` or `SENSITIVE_RECURSIVE_KEYS` as needed.
4. Commit the XML file.

### Plist vs. symlink: when to use which

- **Preference domains** (`~/Library/Preferences/*.plist`): always use `plist_manager.sh`. These are managed by `cfprefsd` and must not be symlinked.
- **App config files** (`~/Library/Application Support/*/config.plist` or similar): symlinks via `home-symlink.sh` are fine when the app reads its config file directly (e.g. Mac Mouse Fix).

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
8. Never hand-edit files in `plists/` — always use `plist_manager.sh backup` to regenerate them from the live system.

## Setup script assumptions

- `macos_setup.sh` is order-sensitive operations code, not a library-style shell script. Preserve phase ordering unless the user explicitly asks to change behavior.
- Keep profile semantics intact:
  - `work` is the default baseline.
  - `personal` extends `work`.
  - `server` is `personal` plus a final `macos_no_animations.sh` run.
- `macos_shortcuts.sh` is designed to be runnable on its own and from `macos_setup.sh`. Keep it standalone.
- App-specific `defaults write` calls can fail on modern macOS when the preference domain lives inside an app container. Prefer the existing wrapper helpers over raw `defaults write` for those domains.
- `AppleSymbolicHotKeys` entries are not guaranteed to exist on every machine. Guard nested plist edits so missing keys do not abort the run.
- `xcode-select --install` is intentionally wrapped because it may print “already installed” and still exit non-zero. Preserve that tolerant handling.
- The Homebrew section intentionally batches installs/uninstalls after one installed-state probe. Avoid reintroducing per-package loops unless there is a concrete need.
- `mas install` requires an active Mac App Store session and may need to prompt the user before continuing.
- `macos_no_animations.sh` is a separate optional pass. If its behavior changes, keep it safe to invoke both directly and from `macos_setup.sh`.
- `plist_manager.sh restore` runs after `bootstrap.sh` in `macos_setup.sh` so that apps installed by Homebrew cask are already present when their preferences are imported.

## Validation checklist after edits

Run relevant checks based on changed files:

```bash
# Shell scripts
bash -n bootstrap.sh home-symlink.sh macos_setup.sh macos_no_animations.sh macos_shortcuts.sh plist_manager.sh

# JSON files (example)
jq . cursor/settings.json >/dev/null

# plist files
plutil -lint “home-symlink/Library/Application Support/com.nuebling.mac-mouse-fix/config.plist”
plutil -lint plists/*.xml
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
bash --noprofile --norc -i -c 'export PS4=”+${EPOCHREALTIME}\t${BASH_SOURCE}:${LINENO}: “; exec 3>”'”$TRACE_FILE”'”; BASH_XTRACEFD=3; set -x; source /Users/lucas/dotfiles/home-symlink/.bashrc; set +x'
echo “$TRACE_FILE”
```

3. Rank hotspots (largest gaps between traced commands first):

```bash
awk 'BEGIN{prev_ts=0;prev_line=””} /^\++[0-9]+\.[0-9]+/{line=$0; sub(/^\++/,””,line); ts=substr(line,1,17)+0; if(prev_ts>0){d=ts-prev_ts; if(d>0.02) printf “%.3fs | %s\n”, d, prev_line} prev_ts=ts; prev_line=$0 }' “$TRACE_FILE” | sort -nr | head -n 30
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
- VS Code / Cursor settings and keybindings:
  - edit under `home-symlink/Library/Application Support/Code/User/` or `home-symlink/Library/Application Support/Cursor/User/`.
- App preference changes (Moom, etc.):
  - adjust settings in the running app, then run `./plist_manager.sh backup` to capture the change.

## Modifying plist / defaults values

- **Flat keys:** `defaults write` is fine for simple top-level values (strings, ints, bools).
- **Nested dictionaries:** Do NOT use `defaults write -dict-add` with old-style plist shorthand like `”{enabled=0;}”` — it replaces the entire sub-dictionary, clobbering sibling keys (e.g. the `value`/`parameters`/`type` sub-dict that macOS maintains).
- **Surgical nested edits:** Use `/usr/libexec/PlistBuddy -c “Set :Path:To:Key value” file.plist` to modify a single key within a nested dict without touching the rest.
- **Verifying changes:** After writing, read back with `defaults read` or `PlistBuddy -c Print` and compare against what System Settings produces to confirm the structure matches.
- **AppleSymbolicHotKeys specifically:** Each entry is a dict with `enabled` (bool) and `value` (dict containing `parameters` array and `type` string). To disable a shortcut, set only `:AppleSymbolicHotKeys:<id>:enabled` to `false` via PlistBuddy.
- **Escaping `$` in NSUserKeyEquivalents:** In `macos_shortcuts.sh`, the `$` modifier (Shift) must be escaped as `\$` inside double-quoted strings, otherwise bash interprets it as a variable reference.
- **Full app preferences:** Do not use `defaults write` to manage entire app preference domains. Use `plist_manager.sh` instead — it handles backup with PII stripping and restore via `defaults import`.

## Non-goals

- Do not treat this repository as a package with unit/integration tests.
- Do not assume scripts are idempotent or safe for unattended CI execution.
