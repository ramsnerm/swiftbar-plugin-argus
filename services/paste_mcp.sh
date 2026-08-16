#!/bin/bash
# ========================================================= Paste MCP ====
# A local macOS app (not a launchd job) - started/stopped via "open"/
# "quit app" instead of launchctl. The bearer token lives in the login
# Keychain and is never written into this script.
service_paste_mcp() {
    TOTAL=$((TOTAL+1))
    local url="http://127.0.0.1:8888/mcp"
    local marker="$STATE_DIR/paste_deliberately_off"
    local token; token=$(security find-generic-password -a "$USER" -s "swiftbar-paste-mcp-token" -w 2>/dev/null)

    local running=0
    pgrep -f "Setapp/Paste.app/Contents/MacOS/Paste$" >/dev/null 2>&1 && running=1
    [ "$running" = "1" ] && rm -f "$marker"

    if [ "$running" = "1" ]; then
        mcp_probe "$url" "$token" 3
    else
        MCP_OK=0
    fi
    [ "$MCP_OK" = "1" ] && HEALTHY=$((HEALTHY+1))

    app_state_sf "$MCP_OK" "$running" "Paste" "$marker"
    add "$STR_PASTE_LABEL | sfimage=$APP_SF"
    note_top_sf "$APP_SF" "$STR_PASTE_LABEL"

    # --- Actions ---
    if [ "$running" = "1" ]; then
        add "--$STR_COMMON_OPEN | bash=$SWIFTBAR_DIR/helpers/paste_open.sh terminal=false refresh=true"
        add "--$STR_COMMON_RESTART | bash=$SWIFTBAR_DIR/helpers/paste_restart.sh terminal=false refresh=true"
        add "--$STR_COMMON_BEENDEN | bash=$SWIFTBAR_DIR/helpers/paste_quit.sh terminal=false refresh=true"
    else
        add "--$STR_COMMON_STARTEN | bash=$SWIFTBAR_DIR/helpers/paste_open.sh terminal=false refresh=true"
    fi

    # --- Separator + info ---
    add "$SEP"
    [ "$MCP_OK" = "1" ] && add "--$(printf "$STR_COMMON_VERSION" "$MCP_VERSION") | size=11"
}
