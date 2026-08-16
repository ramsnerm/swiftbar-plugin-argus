#!/bin/bash
# Updates the ComfyUI git checkout (git pull) and its venv packages
# (pip install -r requirements.txt), then restarts the launchd job.
#
# Deliberately does NOT call the project's own comfyui.sh update command:
# that script stops/starts ComfyUI itself via PID files, which fights with
# launchd's KeepAlive (launchd would just relaunch the old process the
# moment comfyui.sh kills it). Instead this does the git/pip steps
# directly and uses bootout+bootstrap, same pattern as llama_fim_update.sh,
# so launchd stays the single source of truth for the running process.
RT="$HOME/.local/share/swiftbar"
source "$RT/lib/strings.sh"
if [ -f "$RT/lib/config.local.sh" ]; then
    source "$RT/lib/config.local.sh"
else
    source "$RT/lib/config.example.sh"
fi

SRC="$HOME/Applications/ComfyUI/src"
VENV="$HOME/Applications/ComfyUI/venv"
PLIST="$HOME/Library/LaunchAgents/$CFG_COMFYUI_LAUNCHD_LABEL.plist"
DOMAIN="gui/$(id -u)"
LABEL="$CFG_COMFYUI_LAUNCHD_LABEL"

notify() {
    /opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_COMFY_UPDATE_TITLE" \
        -message "$1" -sender "com.ameba.SwiftBar" >/dev/null 2>&1
}

rev_before=$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null)

launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1
sleep 1

if ! git -C "$SRC" pull --ff-only >/dev/null 2>&1; then
    launchctl bootstrap "$DOMAIN" "$PLIST" >/dev/null 2>&1
    notify "$STR_NOTIFY_COMFY_PULL_FAILED"
    exit 1
fi

"$VENV/bin/pip" install -r "$SRC/requirements.txt" >/dev/null 2>&1

rev_after=$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null)
launchctl bootstrap "$DOMAIN" "$PLIST" >/dev/null 2>&1

notify "$(printf "$STR_NOTIFY_COMFY_UPDATE_DONE" "$rev_before" "$rev_after")"
