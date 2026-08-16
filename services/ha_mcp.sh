#!/bin/bash
# =========================================================== HA MCP ====
# Remote service reached via a Home Assistant webhook, likewise with no
# Start/Stop control from here. The response arrives as an SSE frame;
# mcp_probe already handles that shape.
service_ha_mcp() {
    TOTAL=$((TOTAL+1))
    # The webhook URL's ID is itself the entire access credential (Home
    # Assistant webhooks need no separate bearer token - knowing the URL
    # IS the auth), so unlike CFG_GITEA_URL/CFG_HA_UI it lives in the
    # Keychain, not lib/config.local.sh.
    local url; url=$(security find-generic-password -a "$USER" -s "swiftbar-ha-webhook-url" -w 2>/dev/null)
    local ui="$CFG_HA_UI"
    mcp_probe "$url" ""

    local sf
    if [ "$MCP_OK" = "1" ]; then
        HEALTHY=$((HEALTHY+1))
        sf="$SF_OK"
    else
        sf="$SF_ERROR"
    fi
    add "$STR_HA_LABEL | sfimage=$sf"
    note_top_sf "$sf" "$STR_HA_LABEL"

    # --- Actions ---
    add "--$STR_COMMON_OPEN | href=$ui"

    # --- Separator + info ---
    add "$SEP"
    add "--$(printf "$STR_COMMON_EXTERNAL" "$STR_HA_LABEL") | size=11"
    if [ "$MCP_OK" = "1" ]; then
        add "--$(printf "$STR_COMMON_VERSION" "$MCP_VERSION") | size=11"
    fi
}
