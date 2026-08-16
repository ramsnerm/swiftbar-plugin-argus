#!/bin/bash
# Unloads every currently loaded model from Open WebUI's embedded
# llama.cpp router. There is no bulk "unload all" endpoint on the router,
# so this loops over /v1/models and calls /models/unload for each model
# that's currently loaded (same endpoint llama_router_unload.sh uses for
# a single model).
# Usage: llama_router_unload_all.sh <router-port>
port="$1"

models=$(curl -s -m 3 "http://127.0.0.1:$port/v1/models" 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for m in d.get('data',[]):
    if (m.get('status') or {}).get('value') == 'loaded':
        print(m.get('id',''))
" 2>/dev/null)

while IFS= read -r mid; do
    [ -z "$mid" ] && continue
    curl -s -m 8 -X POST "http://127.0.0.1:$port/models/unload" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"$mid\"}" >/dev/null
done <<< "$models"

# refresh=true fires the moment this script exits - wait until the router
# actually reports nothing loaded so the menu doesn't briefly still show
# the old (still loaded) list, same reasoning as comfyui_free.sh.
for _ in $(seq 1 10); do
    still_loaded=$(curl -s -m 2 "http://127.0.0.1:$port/v1/models" 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(1); sys.exit(0)
print(sum(1 for m in d.get('data',[]) if (m.get('status') or {}).get('value') == 'loaded'))
" 2>/dev/null)
    [ "${still_loaded:-0}" -eq 0 ] && break
    sleep 0.5
done
