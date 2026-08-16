#!/bin/bash
# Quit and relaunch Paste in one click. Doesn't touch the "deliberately
# off" marker in between, since the end state is "running" either way.
_tmpdir="${TMPDIR:-/tmp}"
rm -f "${_tmpdir%/}/argus-swiftbar/paste_deliberately_off"
osascript -e 'quit app "Paste"'
sleep 1
open -a "/Applications/Setapp/Paste.app"
