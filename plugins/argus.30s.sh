#!/bin/bash
#
# <bitbar.title>Argus</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Martin Ramsner</bitbar.author>
# <bitbar.desc>One menu bar icon for all local/remote services (mcp-proxy, ComfyUI, ...), each as its own submenu.</bitbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
#
# WHAT THIS IS
# A SwiftBar (https://swiftbar.app) plugin: a shell script that SwiftBar
# re-runs on a timer (see the ".30s." in the filename - every 30 seconds)
# and renders as a macOS menu bar item. Its stdout IS the menu: the first
# line before the first "---" becomes the persistent menu bar title/icon,
# everything after becomes the dropdown, one line per menu item. SwiftBar's
# line syntax is "Title | param1=value param2=value ...".
#
# WHAT IT MONITORS
# Eight services this user runs, in this order: a remote Search Mestro MCP
# server (docs.runmaestro.ai), ComfyUI (local image generation), a remote
# Forgejo/Gitea MCP server, a remote Home Assistant MCP webhook, a local
# llama.cpp server used for code fill-in-the-middle completion, a local
# mcp-proxy (hosts MCP servers over HTTP/SSE), and two local macOS apps
# (Open WebUI, Paste) each exposing their own MCP server.
#
# THIS FILE is only the orchestrator: source the shared libraries and one
# file per service, call each service in order, then print the header/
# footer/notifications. All actual per-service logic lives in services/,
# shared helpers in lib/ - see those files for the real work.
#
# SUBMENU LAYOUT CONVENTION (same for every service)
# 1. Clickable action lines first (Open/Start/Stop/Restart/Quit/Log/Config).
# 2. A separator line.
# 3. Grey/small info lines (including flat sub-lists like hosted MCP
#    servers or loaded models). Building a separator at this nesting depth
#    (one level under a top-level item, i.e. one leading "--") requires
#    FIVE dashes ("-----") - live-tested against SwiftBar: four dashes
#    ("----") render as literal text, not a separator line.
#
# STATUS ICONS
# Status is NOT expressed through text color, but through the SHAPE of a
# monochrome SF Symbol (the sfimage= parameter) - this matches native
# macOS menu bar style, where things like Wi-Fi/Bluetooth/battery are also
# single-color glyphs, never colored dots. Live-tested against SwiftBar:
# sfimage works both on the header line (the persistent icon) and on
# individual dropdown items, and can be combined with color=/size= on the
# same line (color only tints the text, the symbol itself stays
# monochrome/system-colored).
#   ok / loaded            -> checkmark.circle
#   error / should-be-up   -> xmark.circle
#   busy (e.g. rendering)  -> arrow.triangle.2.circlepath
#   starting up            -> circle.dotted
#   deliberately off       -> circle
#   info (version etc.)    -> info.circle
#   calm default (header)  -> point.3.connected.trianglepath.dotted

export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

# Base runtime dir. Deliberately kept OUTSIDE of the "plugins" subfolder:
# SwiftBar scans its plugin folder and tries to load every file in it as
# its own separate menu bar icon (live-verified - a helper script placed
# there showed up as a stray icon). Helpers/lib/services therefore live in
# sibling folders, out of SwiftBar's scan path.
SWIFTBAR_DIR="$HOME/.local/share/swiftbar"

# Personal, non-secret config (real dev path, launchd labels, service
# URLs) lives in lib/config.local.sh - gitignored, never committed, see
# lib/config.example.sh for what it contains. Falls back to the tracked
# example (placeholder values) so a fresh clone still runs, just with
# non-functional Gitea/HA URLs and no "Argus Version" footer entry.
if [ -f "$SWIFTBAR_DIR/lib/config.local.sh" ]; then
    source "$SWIFTBAR_DIR/lib/config.local.sh"
else
    source "$SWIFTBAR_DIR/lib/config.example.sh"
fi
# The actual git-versioned source lives here; SWIFTBAR_DIR/plugins,
# SWIFTBAR_DIR/helpers, SWIFTBAR_DIR/lib and SWIFTBAR_DIR/services are
# symlinks into this folder. Used for the "Argus Version" footer entry
# (commit hash + "reveal in Finder").
ARGUS_DEV_DIR="$CFG_ARGUS_DEV_DIR"

# All user-visible text lives in lib/strings.sh - see that file for the
# naming convention. Change/translate the UI there, not here.
source "$SWIFTBAR_DIR/lib/strings.sh"
# Constants + menu-building primitives (add(), note_top_sf(),
# add_service_actions(), app_state_sf()).
source "$SWIFTBAR_DIR/lib/core.sh"
# Pure formatting/local-lookup helpers.
source "$SWIFTBAR_DIR/lib/text.sh"
# Generic single-field JSON extraction (json_field), used by lib/queries.sh
# and by several services below.
source "$SWIFTBAR_DIR/lib/json.sh"
# Shared query/probe helpers (launchd_info, mcp_probe, *_latest_version).
source "$SWIFTBAR_DIR/lib/queries.sh"

# One file per service - each defines exactly one service_<name> function.
source "$SWIFTBAR_DIR/services/search_mestro_mcp.sh"
source "$SWIFTBAR_DIR/services/comfyui.sh"
source "$SWIFTBAR_DIR/services/gitea_mcp.sh"
source "$SWIFTBAR_DIR/services/ha_mcp.sh"
source "$SWIFTBAR_DIR/services/llama_fim.sh"
source "$SWIFTBAR_DIR/services/mcp_proxy.sh"
source "$SWIFTBAR_DIR/services/openwebui.sh"
source "$SWIFTBAR_DIR/services/paste_mcp.sh"

# Search Mestro is called first deliberately, ahead of alphabetical
# order (its display name would otherwise sort after Paste MCP) - not
# an oversight, don't "fix" it back to alphabetical.
service_search_mestro_mcp
service_comfyui
service_gitea_mcp
service_ha_mcp
service_llama_fim
service_mcp_proxy
service_openwebui
service_paste_mcp

# ================================================================ Header ====
# Priority for the aggregate header icon: a genuine outage (error symbol)
# beats everything else, then "starting up" (dotted, uncertain), then
# "busy" (e.g. ComfyUI rendering); only if none of those apply does it
# show as fully ok.
top_sf="$SF_OK"
for s in "${TOP_SF[@]}"; do
    if [ "$s" = "$SF_ERROR" ]; then top_sf="$SF_ERROR"; break; fi
done
if [ "$top_sf" != "$SF_ERROR" ]; then
    for s in "${TOP_SF[@]}"; do
        if [ "$s" = "$SF_STARTING" ]; then top_sf="$SF_STARTING"; break; fi
    done
fi
if [ "$top_sf" = "$SF_OK" ]; then
    for s in "${TOP_SF[@]}"; do
        if [ "$s" = "$SF_BUSY" ]; then top_sf="$SF_BUSY"; break; fi
    done
fi

# The menu bar icon ALWAYS stays the calm "group" symbol - problems are
# reported as a macOS notification (Notification Center) instead of by
# swapping the icon. SwiftBar's tooltip= parameter is demonstrably broken
# on current macOS (github.com/swiftbar/SwiftBar issue #409) - verified
# live on both the header line and dropdown items, neither showed
# anything - hence this approach instead of a tooltip.
echo " | sfimage=$SF_GROUP"

# Only genuine errors (SF_ERROR) trigger a notification - "starting" and
# "busy" are normal transitional states, not problems.
problem_summary=""
for i in "${!TOP_SF[@]}"; do
    [ "${TOP_SF[$i]}" != "$SF_ERROR" ] && continue
    [ -n "$problem_summary" ] && problem_summary="$problem_summary, "
    problem_summary="$problem_summary${TOP_NAMES[$i]}"
done

# Right after a Mac reboot, network/apps/services need more time to come
# up than a single 30s check allows for - within this window (default 5
# minutes of system uptime) nothing is reported yet, even if something
# currently looks like an error. After that the normal logic applies.
BOOT_GRACE_SECONDS=300
boot_epoch=$(sysctl -n kern.boottime 2>/dev/null | sed -E 's/.*sec = ([0-9]+).*/\1/')
now_epoch=$(date +%s)
in_boot_grace=0
if [ -n "$boot_epoch" ]; then
    uptime_sec=$((now_epoch - boot_epoch))
    [ "$uptime_sec" -lt "$BOOT_GRACE_SECONDS" ] && in_boot_grace=1
fi

# Only notify on a REAL state change (not again on every 30s run) - the
# last known state is kept in a file, since this script restarts from
# scratch on every invocation and has no other way to remember anything.
STATE_FILE="$STATE_DIR/services_alert_state"
mkdir -p "$STATE_DIR"
prev_summary=""
[ -f "$STATE_FILE" ] && prev_summary=$(cat "$STATE_FILE")

if [ "$in_boot_grace" = "1" ]; then
    : # Boot grace period: deliberately do NOT touch the state file, so
      # that once the grace period ends, a problem that is still ongoing
      # is still recognized as "new" and gets reported.
elif [ "$problem_summary" != "$prev_summary" ]; then
    # terminal-notifier instead of plain osascript: this way the native
    # "Show" button that macOS adds to every notification anyway gets a
    # useful action instead of doing nothing (osascript's own notification
    # just opens Script Editor pointlessly on click). This is not an
    # extra button - it's the same button macOS always shows, just wired
    # to something useful.
    #
    # IMPORTANT: launched in the background (&) and NOT waited on -
    # terminal-notifier takes a noticeable moment to register itself with
    # macOS. Blocking here would have meant SwiftBar seeing a delayed/
    # incomplete output for this run, which can cause menu rendering
    # glitches (live-observed: the item that had just changed appeared
    # greyed out; only a full SwiftBar restart fixed it).
    plugin_dir=$(dirname "$0")
    if [ -n "$problem_summary" ]; then
        ( /opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_ERROR_TITLE" -message "$problem_summary" -sender "com.ameba.SwiftBar" \
            -execute "open '$plugin_dir'" >/dev/null 2>&1 & )
    else
        ( /opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_OK_TITLE" -message "$STR_NOTIFY_OK_MESSAGE" -sender "com.ameba.SwiftBar" \
            -execute "open '$plugin_dir'" >/dev/null 2>&1 & )
    fi
    printf '%s' "$problem_summary" > "$STATE_FILE"
fi

# Sanity-check that every helper script the action buttons above depend
# on actually exists and is executable. If the dev source folder that
# SWIFTBAR_DIR/helpers symlinks to ever gets moved, renamed, or deleted,
# every Start/Stop/Restart/Quit button would silently do nothing on click
# with no visible warning anywhere - this catches that case explicitly
# and reports it via its own notification, kept separate from the
# per-service error tracking above so the two don't interfere with each
# other's "already notified" state. Not subject to the boot grace period:
# a missing file is a structural problem, not something that resolves
# itself as the system finishes booting.
EXPECTED_HELPERS=(
    argus_open_devfolder.sh
    claude_mcp_connect.sh
    claude_mcp_disconnect.sh
    comfyui_free.sh
    comfyui_update.sh
    llama_fim_update.sh
    llama_router_unload.sh
    llama_router_unload_all.sh
    manual_launchd_start.sh
    manual_launchd_stop.sh
    mcp_proxy_update.sh
    openwebui_open.sh
    openwebui_quit.sh
    openwebui_restart.sh
    paste_open.sh
    paste_quit.sh
    paste_restart.sh
)
missing_helpers=""
for h in "${EXPECTED_HELPERS[@]}"; do
    [ -x "$SWIFTBAR_DIR/helpers/$h" ] && continue
    [ -n "$missing_helpers" ] && missing_helpers="$missing_helpers, "
    missing_helpers="$missing_helpers$h"
done

CONFIG_STATE_FILE="$STATE_DIR/config_alert_state"
prev_missing=""
[ -f "$CONFIG_STATE_FILE" ] && prev_missing=$(cat "$CONFIG_STATE_FILE")
if [ "$missing_helpers" != "$prev_missing" ]; then
    if [ -n "$missing_helpers" ]; then
        ( /opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_MISCONFIGURED_TITLE" \
            -message "$(printf "$STR_NOTIFY_MISCONFIGURED_MESSAGE" "$missing_helpers")" -sender "com.ameba.SwiftBar" \
            -execute "open '$SWIFTBAR_DIR/helpers'" >/dev/null 2>&1 & )
    fi
    printf '%s' "$missing_helpers" > "$CONFIG_STATE_FILE"
fi

echo "---"
argus_hash=$(git -C "$ARGUS_DEV_DIR" rev-parse --short HEAD 2>/dev/null)
if [ -n "$argus_hash" ]; then
    echo "$(printf "$STR_FOOTER_VERSION" "$argus_hash") | bash=$SWIFTBAR_DIR/helpers/argus_open_devfolder.sh terminal=false"
    echo "---"
fi
printf '%s' "$BODY"
echo "---"
last_update=$(date '+%d.%m.%Y %H:%M:%S')
echo "$(printf "$STR_FOOTER_LAST_UPDATE" "$last_update") | refresh=true"
