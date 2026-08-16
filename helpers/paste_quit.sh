#!/bin/bash
# Marks the app as "deliberately quit" so Argus doesn't report it as an
# error afterwards even though it's a login item that would normally be
# expected to auto-start. Removed again by paste_open.sh.
# Must match the STATE_DIR formula in plugins/services.30s.sh - see the
# comment there for why this lives in $TMPDIR rather than under
# ~/.local/share/swiftbar.
_tmpdir="${TMPDIR:-/tmp}"
state_dir="${_tmpdir%/}/argus-swiftbar"
mkdir -p "$state_dir"
touch "$state_dir/paste_deliberately_off"
osascript -e 'quit app "Paste"'
