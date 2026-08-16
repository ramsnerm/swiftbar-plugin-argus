#!/bin/bash
# Marks the app as "deliberately quit" - see paste_quit.sh for why.
# Must match the STATE_DIR formula in plugins/services.30s.sh.
_tmpdir="${TMPDIR:-/tmp}"
state_dir="${_tmpdir%/}/argus-swiftbar"
mkdir -p "$state_dir"
touch "$state_dir/openwebui_deliberately_off"
osascript -e 'quit app "Open WebUI"'
