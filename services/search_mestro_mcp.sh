#!/bin/bash
# =================================================== Search Mestro MCP ====
# Remote, hosted MCP server (docs.runmaestro.ai) that provides search/
# retrieval over the Maestro documentation site. Public endpoint, no
# bearer token, no Start/Stop control from here - same shape as ha_mcp.sh.
service_search_mestro_mcp() {
    TOTAL=$((TOTAL+1))
    local url="https://docs.runmaestro.ai/mcp"
    local ui="https://docs.runmaestro.ai/"
    mcp_probe "$url" ""

    local sf
    if [ "$MCP_OK" = "1" ]; then
        HEALTHY=$((HEALTHY+1))
        sf="$SF_OK"
    else
        sf="$SF_ERROR"
    fi
    add "$STR_SEARCHMESTRO_LABEL | sfimage=$sf"
    note_top_sf "$sf" "$STR_SEARCHMESTRO_LABEL"

    # --- Actions ---
    add "--$STR_COMMON_OPEN | href=$ui"

    # --- Separator + info ---
    add "$SEP"
    add "--$(printf "$STR_COMMON_EXTERNAL" "$STR_SEARCHMESTRO_LABEL") | size=11"
    if [ "$MCP_OK" = "1" ]; then
        add "--$(printf "$STR_COMMON_VERSION" "$MCP_VERSION") | size=11"
    fi
}
