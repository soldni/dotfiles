#!/usr/bin/env bash

# Backup and restore macOS preference-domain plists as human-readable XML files.
#
# Usage:
#   plist_manager.sh backup  [domain]   Export plist(s) to plists/<domain>.xml
#   plist_manager.sh restore [domain]   Import plists/<domain>.xml into live domain(s)
#
# When <domain> is omitted, the action runs against all TRACKED_DOMAINS.
#
# The backed-up XML files live under the "plists/" directory next to this script
# and are safe to commit to git.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
PLIST_DIR="${SCRIPT_DIR}/plists"

# ── Tracked preference domains ──────────────────────────────────────────────
# Add any preference domain whose plist you want backed up into this repo.
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
    local xml_file="${PLIST_DIR}/${domain}.xml"

    # Read the live preference domain and write it as XML1 into the repo.
    # XML1 is used instead of JSON because some plists contain <date> values
    # that the JSON serializer rejects.
    local plist_path="${HOME}/Library/Preferences/${domain}.plist"
    if [[ ! -f "${plist_path}" ]]; then
        echo "Error: No plist found at ${plist_path}" >&2
        return 1
    fi

    mkdir -p "${PLIST_DIR}"

    # Export to a temp file so we can strip sensitive keys before committing.
    local tmp_plist
    tmp_plist="$(mktemp /tmp/plist_backup.XXXXXX.plist)"
    trap "rm -f '${tmp_plist}'" RETURN

    # Try `defaults export` first for the cfprefsd-merged view. If the
    # domain comes back empty (e.g. symlinked plists that cfprefsd ignores),
    # fall back to converting the on-disk file directly.
    local exported
    exported="$(defaults export "${domain}" - 2>/dev/null || true)"
    if [[ -n "${exported}" ]] && ! echo "${exported}" | grep -q '<dict/>'; then
        echo "${exported}" | plutil -convert xml1 -o "${tmp_plist}" -
    else
        plutil -convert xml1 -o "${tmp_plist}" "${plist_path}"
    fi

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

    cp "${tmp_plist}" "${xml_file}"
    echo "Backed up ${domain} → ${xml_file}"
}

restore_domain() {
    local domain="$1"
    local xml_file="${PLIST_DIR}/${domain}.xml"

    # Import the stored XML back into the live preference domain.
    if [[ ! -f "${xml_file}" ]]; then
        echo "Error: No backup found at ${xml_file}" >&2
        echo "Run '$0 backup ${domain}' first." >&2
        return 1
    fi

    defaults import "${domain}" "${xml_file}"

    echo "Restored ${domain} ← ${xml_file}"
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
