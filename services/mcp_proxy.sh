#!/bin/bash
# ============================================================ mcp-proxy ====
service_mcp_proxy() {
    TOTAL=$((TOTAL+1))
    local label="local.mcp.proxy" port=8899 host=127.0.0.1
    local base="$HOME/Applications/mcp-proxy"
    local conf="$base/server.json" log="$base/proxy.log"
    local plist="$HOME/Library/LaunchAgents/$label.plist"

    launchd_info "$label"
    local listen; listen=$(lsof -nP -iTCP:$port -sTCP:LISTEN -t 2>/dev/null | head -1)

    local rows_meta=""
    [ -f "$conf" ] && rows_meta=$(python3 -c "
import json,sys
try: d=json.load(open('$conf'))
except Exception: sys.exit(0)
for k,v in (d.get('mcpServers') or {}).items():
    if not isinstance(v,dict) or not v.get('enabled',True): continue
    cmd=v.get('command','')
    args=v.get('args',[]) or []
    pkg = args[1] if cmd=='npx' and len(args)>1 and args[0]=='-y' else ''
    print(f\"{k}|{pkg}\")
" 2>/dev/null)
    local names=""
    [ -n "$rows_meta" ] && names=$(printf '%s\n' "$rows_meta" | cut -d'|' -f1)

    local ok=0 total_srv=0 rows=""
    if [ -n "$listen" ]; then
        while IFS='|' read -r name pkg; do
            [ -z "$name" ] && continue
            total_srv=$((total_srv+1))
            local code
            code=$(curl -s -o /dev/null -m 2 -w '%{http_code}' "http://$host:$port/servers/$name/sse" 2>/dev/null)
            if [ "$code" = "200" ]; then ok=$((ok+1)); rows="${rows}${name}|${SF_OK}|${code}|${pkg}"$'\n'
            else rows="${rows}${name}|${SF_ERROR}|${code:-—}|${pkg}"$'\n'; fi
        done <<< "$rows_meta"
    fi

    local sf="$SF_ERROR" label_txt="$STR_MCP_LABEL"
    if [ -n "$listen" ]; then
        HEALTHY=$((HEALTHY+1))
        # The proxy process itself is up - only show it as a genuine error
        # when NONE of its hosted servers work (a full outage). One
        # degraded hosted server out of several is not a proxy problem;
        # the "$ok/$total_srv" label already surfaces that partial state
        # without flipping the whole thing (and the aggregate header icon,
        # and the error notification) to red over a single flaky server.
        if [ "$total_srv" -gt 0 ] && [ "$ok" -eq 0 ]; then sf="$SF_ERROR"; else sf="$SF_OK"; fi
        label_txt=$(printf "$STR_MCP_LABEL_COUNT" "$ok" "$total_srv")
    elif [ "$LOADED" = "1" ] && [ -n "$PID" ]; then
        # The process is already running per launchd, but the port isn't
        # answering yet - typically right after a start/restart, not a
        # genuine error.
        sf="$SF_STARTING"
    elif [ "$LOADED" = "0" ]; then
        # Deliberately removed from launchd via "Deactivate" - launchd
        # isn't even trying to keep this running, so it's not an error.
        sf="$SF_OFF"
    fi
    add "$label_txt | sfimage=$sf"
    note_top_sf "$sf" "$STR_MCP_LABEL"

    local proxy_version; proxy_version=$("$base/venv/bin/mcp-proxy" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    local proxy_latest; proxy_latest=$(pypi_latest_version mcp-proxy)

    # --- Actions ---
    local healthy=0; [ -n "$listen" ] && healthy=1
    add_service_actions "$label" "$plist" "$healthy"
    add "--$STR_COMMON_LOG_OPEN | href=file://$log"
    add "--$STR_MCP_CONFIGURE | href=file://$conf"
    if [ -n "$proxy_latest" ] && [ "$proxy_latest" != "$proxy_version" ]; then
        add "--$(printf "$STR_COMMON_UPDATE_TO" "v$proxy_latest") | bash=$SWIFTBAR_DIR/helpers/mcp_proxy_update.sh terminal=false refresh=true"
    fi
    if [ -n "$names" ]; then
        local claude_connected; claude_connected=$(claude_mcp_user_servers)
        local claude_connected_count=0
        while IFS= read -r n; do
            [ -z "$n" ] && continue
            printf '%s\n' "$claude_connected" | grep -qxF "$n" && claude_connected_count=$((claude_connected_count+1))
        done <<< "$names"
        add "--$(printf "$STR_MCP_CLAUDE_CONNECTION" "$claude_connected_count")"
        while IFS= read -r n; do
            [ -z "$n" ] && continue
            if printf '%s\n' "$claude_connected" | grep -qxF "$n"; then
                add "----$n $STR_MCP_CLAUDE_DISCONNECT_SUFFIX | bash=$SWIFTBAR_DIR/helpers/claude_mcp_disconnect.sh param1=$n terminal=false refresh=true"
            else
                add "----$n $STR_MCP_CLAUDE_CONNECT_SUFFIX | bash=$SWIFTBAR_DIR/helpers/claude_mcp_connect.sh param1=$n param2=$port terminal=false refresh=true"
            fi
        done <<< "$names"
    fi

    # --- Separator + info (hosted servers listed flat, no extra parent item) ---
    add "$SEP"
    if [ -z "$names" ]; then
        add "--$STR_MCP_NO_SERVERS | size=11"
    elif [ -z "$listen" ]; then
        add "--$STR_MCP_NOT_CHECKABLE | size=11"
    else
        while IFS='|' read -r name rsf code pkg; do
            [ -z "$name" ] && continue
            local pkgver=""
            [ -n "$pkg" ] && pkgver=$(npx_package_version "$pkg")
            local suffix=""
            [ "$code" != "200" ] && suffix=$(printf "$STR_COMMON_HTTP_SUFFIX" "$code")
            [ -n "$pkgver" ] && suffix="$suffix · v$pkgver"
            add "--$name$suffix | size=11"
        done <<< "$rows"
    fi

    if [ -n "$proxy_version" ]; then
        add "--$(printf "$STR_COMMON_VERSION" "$proxy_version") | size=11"
    fi
}
