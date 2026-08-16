#!/bin/bash
# Quit and relaunch Open WebUI in one click.
_tmpdir="${TMPDIR:-/tmp}"
rm -f "${_tmpdir%/}/argus-swiftbar/openwebui_deliberately_off"
osascript -e 'quit app "Open WebUI"'
sleep 1
open -a "/Applications/Open WebUI.app"
