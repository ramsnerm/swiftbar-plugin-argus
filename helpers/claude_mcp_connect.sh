#!/bin/bash
# Registers an mcp-proxy-hosted MCP server with Claude Code's user-scope
# config, so this and future Claude Code sessions can use it directly
# without a manual "claude mcp add" each time. The proxy/underlying
# server are unaffected either way - this only changes whether Claude
# Code sessions see the server.
# Usage: claude_mcp_connect.sh <server-name> <proxy-port>
RT="$HOME/.local/share/swiftbar"
if [ -f "$RT/lib/config.local.sh" ]; then
    source "$RT/lib/config.local.sh"
else
    source "$RT/lib/config.example.sh"
fi

name="$1" port="$2"
[ -z "$name" ] || [ -z "$port" ] && exit 1

"$CFG_CLAUDE_BIN" mcp add --transport http "$name" "http://127.0.0.1:$port/servers/$name/mcp" -s user >/dev/null 2>&1
