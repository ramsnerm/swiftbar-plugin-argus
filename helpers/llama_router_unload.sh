#!/bin/bash
# Unloads a single model from Open WebUI's embedded llama.cpp router via
# its /models/unload endpoint. Unlike ComfyUI, this router does support
# per-model unload by ID, so each loaded model gets its own click target.
# Usage: llama_router_unload.sh <router-port> <model-id>
port="$1"
model="$2"
curl -s -m 8 -X POST "http://127.0.0.1:$port/models/unload" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"$model\"}" >/dev/null
