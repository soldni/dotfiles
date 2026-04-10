#!/usr/bin/env bash

# Backup and restore macOS preference-domain plists.
#
# Usage:
#   plist_manager.sh backup  [domain]   Export plist(s) to plists/<domain>.plist
#   plist_manager.sh restore [domain]   Import plists/<domain>.plist into live domain(s)
#
# When <domain> is omitted, the action runs against all TRACKED_DOMAINS.
#
# Both backup and restore will quit the owning app first (derived from the
# domain's bundle identifier) and relaunch it afterward if it was running.
#
# The backed-up plist files live under the "plists/" directory next to this
# script and are safe to commit to git.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
PLIST_DIR="${SCRIPT_DIR}/plists"

# ── Tracked preference domains ──────────────────────────────────────────────
# Add any preference domain whose plist you want backed up into this repo.
# Each entry is just the domain string (e.g. 'com.manytricks.Moom'). The app
# name is derived heuristically for quit/relaunch during restore.
TRACKED_DOMAINS=(
    'com.manytricks.Moom'
)
# ────────────────────────────────────────────────────────────────────────────

# ── Keys to strip during backup (PII, license keys, ephemeral state) ────────
# Patterns matched against key names. Keys matching any pattern are removed
# before the plist is written to the repo, preventing secrets and ephemeral
# machine state from leaking into version control.
#
# Top-level patterns: case-insensitive substring match on top-level keys only.
SENSITIVE_TOP_LEVEL_PATTERNS=(
    'license'
    'serial'
    'registration'
    'email'
    'NSWindow Frame'
)
# Recursive patterns: exact key names stripped at any nesting depth.
SENSITIVE_RECURSIVE_KEYS=(
)
# ────────────────────────────────────────────────────────────────────────────

# ── App-name heuristic ───────────────────────────────────────────────────
# Derive the macOS app name from a preference domain so we can quit it
# before restore. Strategy:
#   1. Find an app bundle whose CFBundleIdentifier matches the domain.
#   2. Fall back to the last component of the domain (e.g. "Moom").
app_name_for_domain() {
    local domain="$1"

    # Search common app locations for a matching bundle identifier.
    local search_dirs=(/Applications "$HOME/Applications" /System/Applications)
    for dir in "${search_dirs[@]}"; do
        [[ -d "${dir}" ]] || continue
        while IFS= read -r -d '' app_bundle; do
            local info_plist="${app_bundle}/Contents/Info.plist"
            [[ -f "${info_plist}" ]] || continue
            local bundle_id
            bundle_id="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${info_plist}" 2>/dev/null || true)"
            if [[ "${bundle_id}" == "${domain}" ]]; then
                # Return the app name without the .app extension.
                basename "${app_bundle}" .app
                return 0
            fi
        done < <(find "${dir}" -maxdepth 2 -name '*.app' -print0 2>/dev/null)
    done

    # Fallback: last segment of the reverse-DNS domain.
    echo "${domain##*.}"
}

# Quit an app by name. Returns 0 whether or not the app was running.
quit_app() {
    local app_name="$1"
    if pgrep -xq "${app_name}"; then
        echo "  Quitting ${app_name}..."
        osascript -e "tell application \"${app_name}\" to quit" 2>/dev/null || true
        # Give it a moment to finish writing preferences.
        sleep 1
    fi
}

# Relaunch an app by name (best-effort, no error on failure).
relaunch_app() {
    local app_name="$1"
    echo "  Relaunching ${app_name}..."
    open -a "${app_name}" 2>/dev/null || true
}
# ────────────────────────────────────────────────────────────────────────────

usage() {
    echo "Usage: $0 {backup|restore} [preference-domain]" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 backup                        # back up all tracked domains" >&2
    echo "  $0 backup  com.manytricks.Moom   # back up one domain" >&2
    echo "  $0 restore                       # restore all tracked domains" >&2
    echo "  $0 restore com.manytricks.Moom   # restore one domain" >&2
    exit 1
}

backup_domain() {
    local domain="$1"
    local plist_file="${PLIST_DIR}/${domain}.plist"

    local app_name
    app_name="$(app_name_for_domain "${domain}")"

    # Quit the app so cfprefsd flushes in-memory state to disk.
    local was_running=false
    if pgrep -xq "${app_name}"; then
        was_running=true
    fi
    quit_app "${app_name}"

    mkdir -p "${PLIST_DIR}"

    # Export to a temp file so we can strip sensitive keys before committing.
    local tmp_plist
    tmp_plist="$(mktemp /tmp/plist_backup.XXXXXX.plist)"
    trap "rm -f '${tmp_plist}'" RETURN

    # Use `defaults export` for the cfprefsd-merged view.
    local exported
    exported="$(defaults export "${domain}" - 2>/dev/null || true)"
    if [[ -z "${exported}" ]] || echo "${exported}" | grep -q '<dict/>'; then
        echo "Error: No preferences found for domain ${domain}" >&2
        [[ "${was_running}" == true ]] && relaunch_app "${app_name}"
        return 1
    fi
    echo "${exported}" | plutil -convert xml1 -o "${tmp_plist}" -

    # Strip sensitive keys (license keys, PII, ephemeral state) so they are
    # never committed to the repo. Uses Python's plistlib to handle both
    # top-level pattern matching and recursive exact-key removal.
    python3 -c "
import plistlib, sys, re

top_patterns = sys.argv[1].split('|')
recursive_keys_raw = sys.argv[2]
recursive_keys = set(recursive_keys_raw.split('|')) if recursive_keys_raw else set()

with open(sys.argv[3], 'rb') as f:
    data = plistlib.load(f)

# Strip top-level keys by case-insensitive substring match.
for key in list(data.keys()):
    for pat in top_patterns:
        if pat.lower() in key.lower():
            del data[key]
            print(f'  Stripped top-level key: {key}')
            break

# Recursively strip exact key names at any depth.
def scrub(obj):
    if isinstance(obj, dict):
        for key in list(obj.keys()):
            if key in recursive_keys:
                del obj[key]
            else:
                scrub(obj[key])
    elif isinstance(obj, list):
        for item in obj:
            scrub(item)

if recursive_keys:
    scrub(data)

with open(sys.argv[3], 'wb') as f:
    plistlib.dump(data, f, fmt=plistlib.FMT_XML)
" \
        "$(IFS='|'; echo "${SENSITIVE_TOP_LEVEL_PATTERNS[*]}")" \
        "$(IFS='|'; echo "${SENSITIVE_RECURSIVE_KEYS[*]}")" \
        "${tmp_plist}"

    cp "${tmp_plist}" "${plist_file}"
    echo "Backed up ${domain} → ${plist_file}"

    [[ "${was_running}" == true ]] && relaunch_app "${app_name}"
}

restore_domain() {
    local domain="$1"
    local plist_file="${PLIST_DIR}/${domain}.plist"

    if [[ ! -f "${plist_file}" ]]; then
        echo "Error: No backup found at ${plist_file}" >&2
        echo "Run '$0 backup ${domain}' first." >&2
        return 1
    fi

    local app_name
    app_name="$(app_name_for_domain "${domain}")"

    # Quit the app before importing preferences (recommended by Many Tricks
    # and generally required so cfprefsd picks up the new values cleanly).
    local was_running=false
    if pgrep -xq "${app_name}"; then
        was_running=true
    fi
    quit_app "${app_name}"

    defaults import "${domain}" "${plist_file}"

    echo "Restored ${domain} ← ${plist_file}"

    [[ "${was_running}" == true ]] && relaunch_app "${app_name}"
}

if [[ $# -lt 1 ]]; then
    usage
fi

action="$1"
domain="${2:-}"

case "${action}" in
    backup|restore)
        ;;
    *)
        usage
        ;;
esac

# Build the list of domains to process.
if [[ -n "${domain}" ]]; then
    domains=("${domain}")
else
    domains=("${TRACKED_DOMAINS[@]}")
fi

failed=0
for d in "${domains[@]}"; do
    if [[ "${action}" == "backup" ]]; then
        if ! backup_domain "${d}"; then
            echo "Warning: failed to back up ${d}" >&2
            failed=1
        fi
    else
        if ! restore_domain "${d}"; then
            echo "Warning: failed to restore ${d}" >&2
            failed=1
        fi
    fi
done

if [[ "${failed}" -eq 1 ]]; then
    echo "" >&2
    echo "Some domains failed. See warnings above." >&2
    exit 1
fi
