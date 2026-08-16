#!/bin/bash
# Reveals the Argus dev/git folder in Finder - the "Argus Version" footer
# entry's click action.
RT="$HOME/.local/share/swiftbar"
if [ -f "$RT/lib/config.local.sh" ]; then
    source "$RT/lib/config.local.sh"
else
    source "$RT/lib/config.example.sh"
fi
open "$CFG_ARGUS_DEV_DIR"
