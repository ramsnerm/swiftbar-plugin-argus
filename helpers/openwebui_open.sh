#!/bin/bash
# Clears the "deliberately off" marker, then opens (or brings to front)
# Open WebUI. This is a separate helper script rather than an inline
# SwiftBar bash= command because the app's name contains a space
# ("Open WebUI.app"), which SwiftBar's param1=/param2= parsing breaks on
# - live-verified bug, the button silently did nothing when tried inline.
_tmpdir="${TMPDIR:-/tmp}"
rm -f "${_tmpdir%/}/argus-swiftbar/openwebui_deliberately_off"
open -a "/Applications/Open WebUI.app"
