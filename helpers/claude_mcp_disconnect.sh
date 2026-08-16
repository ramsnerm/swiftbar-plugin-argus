#!/bin/bash
# Removes an MCP server from Claude Code's user-scope config. The proxy
# and the underlying server keep running unaffected (still reachable
# for anything else that talks to the proxy directly, e.g. Open WebUI) -
# this only disconnects Claude Code sessions from it.
# Usage: claude_mcp_disconnect.sh <server-name>
RT="$HOME/.local/share/swiftbar"
if [ -f "$RT/lib/config.local.sh" ]; then
    source "$RT/lib/config.local.sh"
else
    source "$RT/lib/config.example.sh"
fi

name="$1"
[ -z "$name" ] && exit 1

"$CFG_CLAUDE_BIN" mcp remove "$name" -s user >/dev/null 2>&1
