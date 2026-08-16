#!/bin/bash
# Unloads all currently loaded ComfyUI models via its /free endpoint.
# There is no per-model unload in ComfyUI's core API, only "unload
# everything" - see argus.30s.sh (service_comfyui) for why this is
# the only unload action offered.
curl -s -m 8 -X POST -H "Content-Type: application/json" \
  -d '{"unload_models":true,"free_memory":true}' http://127.0.0.1:8188/free >/dev/null

# The /free call returns as soon as ComfyUI accepts the request, not once
# unloading is actually done - SwiftBar's refresh=true fires the moment
# this script exits, so without waiting here the menu would refresh and
# still show the old (still loaded) models for a moment. Poll until the
# loaded-models list is actually empty, capped so a stuck unload can't
# hang the click forever.
for _ in $(seq 1 10); do
    still_loaded=$(curl -s -m 2 "http://127.0.0.1:8188/martin/loaded_models" 2>/dev/null | \
        python3 -c "import json,sys
try: d=json.load(sys.stdin)
except Exception: print(1); sys.exit(0)
print(len(d.get('loaded_models',[])))" 2>/dev/null)
    [ "${still_loaded:-0}" -eq 0 ] && break
    sleep 0.5
done
