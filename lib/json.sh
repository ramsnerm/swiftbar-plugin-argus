#!/bin/bash
# Generic single-field JSON extraction for the common "one object, pull a
# few (possibly nested) fields" shape used across several services'
# /props, /system_stats, /api/config, etc. responses.
#
# Deliberately NOT for array filtering/counting/row-building (MCP Proxy's
# hosted-server list, Open WebUI's loaded-model list, ComfyUI's
# loaded-model list) - those differ too much per endpoint (different
# field names, filter conditions, output shapes) to generalize without
# ending up with more parameters than the inline code they'd replace.
# Those stay as their own small python blocks in each service file.

# Usage: json_field "$json_string" "dotted.path.to.field" "default"
json_field() {
    local json="$1" path="$2" default="$3"
    printf '%s' "$json" | python3 -c "
import json,sys
path = '$path'.split('.')
default = '$default'
try:
    d = json.load(sys.stdin)
    for p in path:
        if not isinstance(d, dict):
            d = None
            break
        d = d.get(p)
    print(d if d is not None else default)
except Exception:
    print(default)
" 2>/dev/null
}
