#!/bin/bash
# Points the llama FIM launchd job at the newest llama.cpp build that
# Open WebUI has already downloaded for itself under its own app support
# folder. This does NOT fetch anything new - Open WebUI updates its
# bundled llama.cpp independently and keeps every build it has ever
# downloaded in its own versioned subfolder; this script only switches
# which already-present build the FIM server points at.
#
# Editing the plist alone is not enough: launchd caches the job
# definition it loaded, so a plain "kickstart -k" restart would just
# relaunch the OLD binary path again. bootout+bootstrap forces launchd to
# re-read the plist from disk.
source "$HOME/.local/share/swiftbar/lib/strings.sh"

BUILD_DIR="$HOME/Library/Application Support/open-webui/llama.cpp"
PLIST="$HOME/Library/LaunchAgents/local.llama-fim-server.plist"
DOMAIN="gui/$(id -u)"
LABEL="local.llama-fim-server"

current=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$PLIST" 2>/dev/null | grep -oE 'b[0-9]+' | head -1)
newest=$(ls -1 "$BUILD_DIR" 2>/dev/null | grep -E '^b[0-9]+$' | sort -V | tail -1)

if [ -z "$newest" ]; then
    /opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_FIM_UPDATE_TITLE" \
        -message "$STR_NOTIFY_FIM_NO_BUILD" -sender "com.ameba.SwiftBar" >/dev/null 2>&1
    exit 1
fi

new_binary="$BUILD_DIR/$newest/llama-$newest/llama-server"
if [ ! -x "$new_binary" ]; then
    /opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_FIM_UPDATE_TITLE" \
        -message "$(printf "$STR_NOTIFY_FIM_BINARY_MISSING" "$newest")" -sender "com.ameba.SwiftBar" >/dev/null 2>&1
    exit 1
fi

/usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $new_binary" "$PLIST"
launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1
sleep 1
launchctl bootstrap "$DOMAIN" "$PLIST" >/dev/null 2>&1

/opt/homebrew/bin/terminal-notifier -title "$STR_NOTIFY_FIM_UPDATE_TITLE" \
    -message "$(printf "$STR_NOTIFY_FIM_UPDATE_DONE" "$current" "$newest")" -sender "com.ameba.SwiftBar" >/dev/null 2>&1
