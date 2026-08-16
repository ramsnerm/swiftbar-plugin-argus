#!/bin/bash
# Upgrades mcp-proxy inside its own venv via pip, then restarts the
# launchd job so the new version takes effect. Runs as a background
# click action (SwiftBar doesn't wait for it), so it reports its own
# result via a notification instead of via the menu.
source "$HOME/.local/share/swiftbar/lib/strings.sh"

VENV="$HOME/Applications/mcp-proxy/venv"
DOMAIN="gui/$(id -u)"
LABEL="local.mcp.proxy"

old_version=$("$VENV/bin/pip" show mcp-proxy 2>/dev/null | awk -F': ' '/^Version:/{print $2}')

if "$VENV/bin/pip" install --upgrade mcp-proxy >/dev/null 2>&1; then
    new_version=$("$VENV/bin/pip" show mcp-proxy 2>/dev/null | awk -F': ' '/^Version:/{print $2}')
    launchctl kickstart -k "$DOMAIN/$LABEL" >/dev/null 2>&1
    /opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_MCP_UPDATE_TITLE" \
        -message "$(printf "$STR_NOTIFY_MCP_UPDATE_DONE" "$old_version" "$new_version")" -sender "com.ameba.SwiftBar" >/dev/null 2>&1
else
    /opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_MCP_UPDATE_TITLE" \
        -message "$STR_NOTIFY_MCP_UPDATE_FAILED" -sender "com.ameba.SwiftBar" >/dev/null 2>&1
fi
