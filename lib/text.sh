#!/bin/bash
# Pure formatting/local-lookup helpers - no network, no shared state.

gb() { python3 -c "print(f'{$1/1073741824:.1f}')" 2>/dev/null || echo "?"; }

# Read the version of an npm package that was launched via "npx" out of
# npx's local cache (~/.npm/_npx/<hash>/node_modules/<package>/package.json).
# Returns empty if it can't be found.
npx_package_version() {
    local pkg="$1" pkgjson
    pkgjson=$(find "$HOME/.npm/_npx" -maxdepth 6 -path "*/node_modules/$pkg/package.json" 2>/dev/null | head -1)
    [ -z "$pkgjson" ] && return
    python3 -c "import json; print(json.load(open('$pkgjson')).get('version',''))" 2>/dev/null
}
