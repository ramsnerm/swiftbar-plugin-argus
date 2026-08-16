#!/bin/bash
# Clears the "deliberately off" marker set by paste_quit.sh, then opens
# (or brings to front) the Paste app.
_tmpdir="${TMPDIR:-/tmp}"
rm -f "${_tmpdir%/}/argus-swiftbar/paste_deliberately_off"
open -a "/Applications/Setapp/Paste.app"
