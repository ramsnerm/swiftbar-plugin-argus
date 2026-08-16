#!/bin/bash
# ============================================================== ComfyUI ====
service_comfyui() {
    TOTAL=$((TOTAL+1))
    local label="$CFG_COMFYUI_LAUNCHD_LABEL" port=8188 host=127.0.0.1
    local log="$HOME/Applications/ComfyUI/comfyui-launchd.log"
    local ui="http://$host:$port/"
    local plist="$HOME/Library/LaunchAgents/$label.plist"

    launchd_info "$label"
    local stats queue
    stats=$(curl -s -m 3 "http://$host:$port/system_stats" 2>/dev/null)
    queue=$(curl -s -m 3 "http://$host:$port/queue" 2>/dev/null)

    local sf="$SF_ERROR" label_txt="$STR_COMFY_LABEL"
    local version=""
    local running="" pending="" lm_rows=""
    if [ -n "$stats" ]; then
        HEALTHY=$((HEALTHY+1))
        version=$(json_field "$stats" "system.comfyui_version" "?")
        # queue_running/queue_pending are arrays - counting them needs the
        # array-aware inline parser below, json_field only does single
        # fields (see lib/json.sh for why).
        read -r running pending <<< "$(printf '%s' "$queue" | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(0,0); sys.exit(0)
print(len(d.get('queue_running',[])), len(d.get('queue_pending',[])))
" 2>/dev/null)"
        # Custom route (see the martin-loaded-models-api custom node in the
        # ComfyUI install) - neither ComfyUI core nor the Crystools
        # extension expose checkpoint names, only utilization percentages.
        # This route reads ComfyUI's internal in-memory model cache directly.
        local lm_json; lm_json=$(curl -s -m 3 "http://$host:$port/martin/loaded_models" 2>/dev/null)
        lm_rows=$(printf '%s' "$lm_json" | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for m in d.get('loaded_models',[]):
    gb=m.get('memory_loaded_bytes',0)/1073741824
    print(f\"{m.get('architecture','?')}|{m.get('device','?')}|{gb:.1f}\")
" 2>/dev/null)
        local lm_count=0
        [ -n "$lm_rows" ] && lm_count=$(printf '%s\n' "$lm_rows" | grep -c .)

        if [ "${running:-0}" -gt 0 ]; then sf="$SF_BUSY"; label_txt="${STR_COMFY_LABEL}${STR_COMFY_RENDERING_SUFFIX}"
        else sf="$SF_OK"; label_txt="$STR_COMFY_LABEL"; fi
        if [ "$lm_count" -eq 1 ]; then label_txt="$label_txt $(printf "$STR_COMMON_COUNT_PAREN" "1" "$STR_UNIT_MODEL_ONE")"
        elif [ "$lm_count" -gt 1 ]; then label_txt="$label_txt $(printf "$STR_COMMON_COUNT_PAREN" "$lm_count" "$STR_UNIT_MODEL_MANY")"; fi
    elif [ "$LOADED" = "1" ] && [ -n "$PID" ]; then
        sf="$SF_STARTING"
    elif [ "$LOADED" = "0" ]; then
        sf="$SF_OFF"
    fi
    add "$label_txt | sfimage=$sf"
    note_top_sf "$sf" "$STR_COMFY_LABEL"

    local comfy_src="$HOME/Applications/ComfyUI/src"
    local comfy_local; comfy_local=$(git -C "$comfy_src" rev-parse HEAD 2>/dev/null)
    local comfy_remote; comfy_remote=$(git_remote_head "$comfy_src")

    # --- Actions ---
    [ -n "$stats" ] && add "--$STR_COMMON_OPEN | href=$ui"
    local healthy=0; [ -n "$stats" ] && healthy=1
    add_service_actions "$label" "$plist" "$healthy"
    add "--$STR_COMMON_LOG_OPEN | href=file://$log"
    if [ -n "$comfy_remote" ] && [ "$comfy_remote" != "$comfy_local" ]; then
        add "--$(printf "$STR_COMFY_UPDATE" "${comfy_remote:0:7}") | bash=$SWIFTBAR_DIR/helpers/comfyui_update.sh terminal=false refresh=true"
    fi
    # ComfyUI has no per-model unload, unlike the Open WebUI router below -
    # its /free endpoint only knows "unload everything", not a single
    # model by ID - so this is one single, honestly-labeled action. Only
    # shown when there is actually something to unload, and not while a
    # render is running (unloading mid-render would kill the in-progress job).
    if [ "$lm_count" -eq 1 ] && [ "${running:-0}" -eq 0 ]; then
        add "--$STR_COMMON_UNLOAD_ONE | bash=$SWIFTBAR_DIR/helpers/comfyui_free.sh terminal=false refresh=true"
    elif [ "$lm_count" -gt 1 ] && [ "${running:-0}" -eq 0 ]; then
        add "--$STR_COMMON_UNLOAD_MANY | bash=$SWIFTBAR_DIR/helpers/comfyui_free.sh terminal=false refresh=true"
    fi

    # --- Separator + info ---
    add "$SEP"
    if [ -n "$stats" ]; then
        add "--$(printf "$STR_COMFY_QUEUE" "${running:-0}" "${pending:-0}") | size=11"
        if [ -z "$lm_rows" ]; then
            add "--$STR_COMMON_NO_MODELS_LOADED | size=11"
        else
            while IFS='|' read -r arch dev mgb; do
                [ -z "$arch" ] && continue
                add "--$(printf "$STR_COMFY_MODEL_ROW" "$arch" "$dev" "$mgb") | size=11"
            done <<< "$lm_rows"
        fi
        add "--$(printf "$STR_COMMON_VERSION" "$version") | size=11"
    fi
}
