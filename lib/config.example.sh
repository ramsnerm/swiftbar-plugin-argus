#!/bin/bash
# Personal, non-secret configuration - copy this file to config.local.sh
# (gitignored, never committed) and fill in your own values. This
# example file stays tracked with placeholders so the repo is usable as
# a reference without leaking anything from the author's own setup.
#
# Genuine secrets (bearer tokens, webhook IDs that double as an access
# credential) do NOT belong here even in config.local.sh - those go in
# the macOS Keychain instead, see README.md > Credentials.

# Absolute path to wherever you keep this repo. Used only for the
# "Argus Version" footer entry (commit hash + "reveal in Finder").
CFG_ARGUS_DEV_DIR="$HOME/path/to/this/repo"

# The launchd job label your ComfyUI LaunchAgent plist is registered
# under (see the <key>Label</key> in your own plist).
CFG_COMFYUI_LAUNCHD_LABEL="com.example.comfyui"

# Your Forgejo/Gitea MCP server. CFG_GITEA_MCP_URL is the MCP endpoint
# itself (used for the health probe); CFG_FORGEJO_UI is the web UI a
# click on "Open" should land on.
CFG_GITEA_MCP_URL="https://your-forgejo-mcp-host/mcp"
CFG_FORGEJO_UI="https://your-forgejo-host/"

# Your Home Assistant web UI (the "Open" action). The webhook URL
# itself is NOT here - a Home Assistant webhook's ID in the URL is its
# entire access credential, so that one lives in the Keychain instead
# (service name "swiftbar-ha-webhook-url", see README.md > Credentials).
CFG_HA_UI="https://your-home-assistant-host/"
