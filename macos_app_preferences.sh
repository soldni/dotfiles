#!/usr/bin/env bash

# Shared helpers for app preferences. Sourcing this file changes no settings.
skipped_app_domains=""

app_is_installed() {
    local domain="$1"

    # Scan bundles once per process, including Utilities and symlinked apps.
    # Preference files and containers can remain after an app is uninstalled.
    if [[ -z "${installed_app_domains+x}" ]]; then
        local app_bundle
        installed_app_domains="$(
            while IFS= read -r -d '' app_bundle; do
                [[ -f "${app_bundle}/Contents/Info.plist" ]] || continue
                /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
                    "${app_bundle}/Contents/Info.plist" 2>/dev/null || true
            done < <(find /Applications "$HOME/Applications" /System/Applications \
                -name '*.app' -prune -print0 2>/dev/null)
        )"
    fi

    grep -Fqx -- "$domain" <<< "$installed_app_domains"
}

# Only use this for app bundle identifiers, not macOS service/global domains.
write_app_defaults() {
    local domain="$1"
    shift

    case ",${skipped_app_domains}," in
        *,"${domain}",*) return 0 ;;
    esac

    if ! app_is_installed "$domain"; then
        printf 'Skipping defaults writes for %s: app is not installed.\n' "$domain" >&2
        skipped_app_domains="${skipped_app_domains},${domain}"
        return 0
    fi

    local output retry
    local settings_opened=false
    while ! output=$(defaults write "$domain" "$@" 2>&1); do
        # Installed apps can still reject CLI access to their sandbox container.
        if [[ "$output" != *"Could not write domain "*"/Library/Containers/"* ]]; then
            printf '%s\n' "$output" >&2
            return 1
        fi

        # macOS requires the user to grant this permission in System Settings.
        if [[ "$settings_opened" == false ]]; then
            printf 'macOS blocked access to container preferences for %s.\n' "$domain" >&2
            printf '%s\n' \
                'Enable the terminal app running this script (e.g. Terminal, iTerm, Ghostty) in System Settings > Privacy & Security > Full Disk Access.' \
                'If access is still blocked, quit and reopen that terminal app, then rerun the script.' >&2
            if [[ -t 0 && -t 2 ]]; then
                open 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles' >/dev/null 2>&1 || true
            fi
            settings_opened=true
        fi

        if [[ -t 0 && -t 2 ]] &&
            read -r -p "Retry the write for ${domain}? [y/N] " retry &&
            [[ "$retry" == [yY] || "$retry" == [yY][eE][sS] ]]; then
            continue
        fi

        printf 'Skipping defaults writes for %s: macOS blocked CLI access to that app container preference domain.\n' "$domain" >&2
        skipped_app_domains="${skipped_app_domains},${domain}"
        return 0
    done
}
