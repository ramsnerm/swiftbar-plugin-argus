#!/bin/bash
# ============================================================ Gitea MCP ====
# Remote service (not running on this Mac) - no launchd, so no
# Start/Stop/Restart is possible here. Health is checked via a real
# MCP JSON-RPC "initialize" handshake, not a plain GET/ping - a bare
# reachability check would have wrongly reported 404 instead of a real
# health status (the server only answers a properly formed POST).
service_gitea_mcp() {
    TOTAL=$((TOTAL+1))
    local url="$CFG_GITEA_MCP_URL"
    local ui="$CFG_FORGEJO_UI"
    mcp_probe "$url" ""

    local sf
    if [ "$MCP_OK" = "1" ]; then
        HEALTHY=$((HEALTHY+1))
        sf="$SF_OK"
    else
        sf="$SF_ERROR"
    fi
    add "$STR_GITEA_LABEL | sfimage=$sf"
    note_top_sf "$sf" "$STR_GITEA_LABEL"

    # --- Actions ---
    add "--$STR_COMMON_OPEN | href=$ui"

    # --- Separator + info ---
    add "$SEP"
    add "--$(printf "$STR_COMMON_EXTERNAL" "$STR_GITEA_LABEL") | size=11"
    if [ "$MCP_OK" = "1" ]; then
        add "--$(printf "$STR_COMMON_VERSION" "$MCP_VERSION") | size=11"
    fi
}
