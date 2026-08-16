#!/bin/bash
# Shared query/probe helpers - things that actively fetch state from
# launchd, a local/remote HTTP endpoint, or an external registry.
# Requires lib/json.sh (json_field) and STATE_DIR (lib/core.sh) to
# already be sourced.

# Fetch launchd info for one job label. Sets STATE, PID, EXITCODE, and
# LOADED (1 if the job is registered with launchd at all, 0 if not -
# "not loaded" happens after a deliberate "Deactivate", see
# add_service_actions in lib/core.sh).
launchd_info() {
    local label="$1"
    local info
    info=$(launchctl print "$DOMAIN/$label" 2>/dev/null)
    if [ -z "$info" ]; then
        STATE="nicht geladen"; PID=""; EXITCODE=""; LOADED=0
        return
    fi
    LOADED=1
    STATE=$(printf '%s\n' "$info" | awk -F' = ' '/^[[:space:]]*state = /{print $2; exit}')
    PID=$(printf '%s\n' "$info" | awk -F' = ' '/^[[:space:]]*pid = /{print $2; exit}')
    EXITCODE=$(printf '%s\n' "$info" | awk -F' = ' '/^[[:space:]]*last exit code = /{print $2; exit}')
}

# A real MCP JSON-RPC "initialize" handshake against an endpoint (local or
# remote, with an optional bearer token) - not just a plain GET/ping, since
# a bare GET against several of these endpoints returns a misleading 404
# even though the server is healthy (it just doesn't answer a bare GET).
# Sets MCP_OK (0/1), MCP_NAME, MCP_VERSION. Responses arrive either as
# plain JSON or as an SSE frame ("event: message\ndata: {...}") depending
# on the server - both shapes are handled.
mcp_probe() {
    local url="$1" bearer="$2" timeout="${3:-5}"
    local args=(-s -m "$timeout" -X POST -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream")
    [ -n "$bearer" ] && args+=(-H "Authorization: Bearer $bearer")
    local resp
    resp=$(curl "${args[@]}" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"swiftbar-monitor","version":"1"}}}' "$url" 2>/dev/null)
    local json; json=$(printf '%s\n' "$resp" | grep -m1 '^data: ' | sed 's/^data: //')
    [ -z "$json" ] && json="$resp"
    MCP_NAME=$(json_field "$json" "result.serverInfo.name" "?" | tr ' ' '_')
    MCP_VERSION=$(json_field "$json" "result.serverInfo.version" "?")
    [ -z "$MCP_NAME" ] && MCP_NAME="?"
    if [ "$MCP_NAME" != "?" ]; then MCP_OK=1; else MCP_OK=0; fi
}

# Latest version of a PyPI package, cached to STATE_DIR with a TTL so the
# 30s refresh cycle doesn't hit the network every time - only queries PyPI
# once per TTL window, otherwise reuses the cached value. On network
# failure (offline, timeout) falls back to whatever is cached, even if
# stale, rather than showing nothing.
pypi_latest_version() {
    local pkg="$1" ttl="${2:-21600}"
    local cache="$STATE_DIR/pypi_latest_${pkg}"
    local now cached_ts=0 cached_ver=""
    now=$(date +%s)
    if [ -f "$cache" ]; then
        read -r cached_ts cached_ver < "$cache"
    fi
    if [ $((now - cached_ts)) -ge "$ttl" ]; then
        local fetched
        fetched=$(json_field "$(curl -s -m 3 "https://pypi.org/pypi/$pkg/json" 2>/dev/null)" "info.version" "")
        if [ -n "$fetched" ]; then
            cached_ver="$fetched"
            mkdir -p "$STATE_DIR"
            printf '%s %s\n' "$now" "$cached_ver" > "$cache"
        fi
    fi
    printf '%s' "$cached_ver"
}

# Latest commit SHA on a git repo's remote HEAD, cached to STATE_DIR with a
# TTL - same reasoning as pypi_latest_version: "git ls-remote" is a network
# call, and we don't want the 30s refresh cycle to make one every time.
git_remote_head() {
    local dir="$1" ttl="${2:-21600}"
    local key; key=$(printf '%s' "$dir" | shasum | cut -c1-12)
    local cache="$STATE_DIR/git_remote_${key}"
    local now cached_ts=0 cached_sha=""
    now=$(date +%s)
    if [ -f "$cache" ]; then
        read -r cached_ts cached_sha < "$cache"
    fi
    if [ $((now - cached_ts)) -ge "$ttl" ]; then
        local fetched
        fetched=$(git -C "$dir" ls-remote origin HEAD 2>/dev/null | awk '{print $1}')
        if [ -n "$fetched" ]; then
            cached_sha="$fetched"
            mkdir -p "$STATE_DIR"
            printf '%s %s\n' "$now" "$cached_sha" > "$cache"
        fi
    fi
    printf '%s' "$cached_sha"
}

# Latest available Open WebUI app version per its own /api/version/updates
# endpoint (requires a Bearer token - an API key generated in Open WebUI's
# own Settings > Account > API Keys, stored in the login Keychain, never
# in this script). This is a genuine "check for update" call the app
# exposes, not a trigger - it can only report a newer version exists, not
# install it. Cached to STATE_DIR with a TTL, same reasoning as the other
# *_latest_version helpers.
owui_latest_version() {
    local ttl="${1:-21600}"
    local cache="$STATE_DIR/owui_latest_version"
    local now cached_ts=0 cached_ver=""
    now=$(date +%s)
    if [ -f "$cache" ]; then
        read -r cached_ts cached_ver < "$cache"
    fi
    if [ $((now - cached_ts)) -ge "$ttl" ]; then
        local token; token=$(security find-generic-password -a "$USER" -s "swiftbar-openwebui-api-key" -w 2>/dev/null)
        if [ -n "$token" ]; then
            local fetched
            fetched=$(json_field "$(curl -s -m 3 -H "Authorization: Bearer $token" "http://127.0.0.1:8080/api/version/updates" 2>/dev/null)" "latest" "")
            if [ -n "$fetched" ]; then
                cached_ver="$fetched"
                mkdir -p "$STATE_DIR"
                printf '%s %s\n' "$now" "$cached_ver" > "$cache"
            fi
        fi
    fi
    printf '%s' "$cached_ver"
}
