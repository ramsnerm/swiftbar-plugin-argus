#!/bin/bash
# Shared constants and the menu-building primitives every service file
# uses (add(), note_top_sf(), add_service_actions(), app_state_sf()).
# Requires SWIFTBAR_DIR to already be set by the caller.

GREY="#8e8e93"
SEP="-----"

SF_OK="checkmark.circle"
SF_ERROR="xmark.circle"
SF_BUSY="arrow.triangle.2.circlepath"
SF_STARTING="circle.dotted"
SF_OFF="circle"
SF_INFO="info.circle"
SF_GROUP="point.3.connected.trianglepath.dotted"

# Ephemeral runtime state (deliberately-off markers, last notified alert)
# lives in the user's real macOS temp directory, not under SWIFTBAR_DIR -
# this is throwaway data that only needs to survive between 30s script
# runs, not real persisted app data, so a temp dir is the semantically
# correct place for it (also gets cleaned up by macOS automatically).
# ${TMPDIR:-/tmp} falls back to /tmp on the rare chance TMPDIR is unset in
# whatever context this script gets invoked from; ${x%/} strips a trailing
# slash first since TMPDIR itself already ends in one but the /tmp
# fallback doesn't - without that, the fallback path would come out as
# the broken "/tmpargus-swiftbar" (no separator). This exact same formula
# is duplicated in the helper scripts that also touch state (they run as
# their own separate processes and can't see this variable).
_tmpdir="${TMPDIR:-/tmp}"
STATE_DIR="${_tmpdir%/}/argus-swiftbar"

DOMAIN="gui/$(id -u)"

# Fetch the list of macOS login items once per run (System Events calls
# are slow, so this is done once here rather than per service).
LOGIN_ITEMS=$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null)

HEALTHY=0
TOTAL=0
BODY=""
TOP_SF=()
TOP_NAMES=()

add() { BODY="${BODY}${1}"$'\n'; }
# Remember a service's top-level status symbol for the aggregate header
# icon, plus its display name for a possible notification message.
note_top_sf() { TOP_SF+=("$1"); TOP_NAMES+=("$2"); }

# Append only the clickable control lines for a launchd job (belongs at
# the top of a submenu). Uses LOADED/PID set by the preceding launchd_info
# call. SwiftBar has no "disabled=" for menu items, so instead of greying
# an item out, the one that doesn't apply right now is simply omitted.
#
# Two states:
#   - Registered with launchd (LOADED=1, the normal case, KeepAlive
#     active): only Restart + Deactivate. A plain Stop would be pointless
#     here - launchd relaunches it itself within seconds - so it's not
#     offered at all in this state.
#   - Deactivated (LOADED=0, bootout'd - launchd isn't managing it at
#     all): Activate (proper launchd registration) is always available,
#     PLUS a one-time manual Start/Stop of the bare process, independent
#     of launchd (manual_launchd_start.sh/manual_launchd_stop.sh), for
#     trying it out without committing to full registration. Which of
#     Start/Stop shows depends on the caller's own health probe ($3,
#     "healthy") - each service already knows whether it's reachable, no
#     need for a separate pgrep check here.
add_service_actions() {
    local label="$1" plist="$2" healthy="$3" indent="${4:---}"
    if [ "$LOADED" = "1" ]; then
        add "${indent}${STR_COMMON_RESTART} | bash=/bin/launchctl param1=kickstart param2=-k param3=$DOMAIN/$label terminal=false refresh=true"
        add "${indent}${STR_COMMON_DEACTIVATE_PERMANENT} | bash=/bin/launchctl param1=bootout param2=$DOMAIN/$label terminal=false refresh=true"
    else
        if [ "$healthy" = "1" ]; then
            add "${indent}${STR_COMMON_STOP_TEMP} | bash=$SWIFTBAR_DIR/helpers/manual_launchd_stop.sh param1=$plist terminal=false refresh=true"
        else
            add "${indent}${STR_COMMON_START} | bash=$SWIFTBAR_DIR/helpers/manual_launchd_start.sh param1=$plist terminal=false refresh=true"
        fi
        add "${indent}${STR_COMMON_ACTIVATE_PERMANENT} | bash=/bin/launchctl param1=bootstrap param2=$DOMAIN param3=$plist terminal=false refresh=true"
    fi
}

# Classify the state of an app that is NOT a launchd job (Paste, Open
# WebUI): running / starting up / deliberately off (quit via our own
# "Quit" button, marker file present) / unexpectedly off (the app IS a
# login item - so it's expected to be running - but isn't, AND wasn't
# quit deliberately through our button; that combination suggests a crash
# or similar, so it's treated as a genuine error).
# Sets APP_SF.
app_state_sf() {
    local app_ok="$1" running="$2" app_name="$3" marker="$4"
    if [ "$app_ok" = "1" ]; then
        APP_SF="$SF_OK"; return
    fi
    if [ "$running" = "1" ]; then
        APP_SF="$SF_STARTING"; return
    fi
    if [ -f "$marker" ]; then
        APP_SF="$SF_OFF"; return
    fi
    if printf '%s' "$LOGIN_ITEMS" | grep -qi "$app_name"; then
        APP_SF="$SF_ERROR"
    else
        APP_SF="$SF_OFF"
    fi
}
