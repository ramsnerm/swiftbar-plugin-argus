#!/bin/bash
# ======================================================== Open WebUI ====
# An Electron app (not a launchd job with a fixed plist - the app
# registers itself with launchd under a random ID each launch). Started/
# stopped the same way as Paste, via "open"/"quit app". Its embedded
# llama.cpp router (port 18881) spins up one process per requested model
# on a random port - /v1/models reports the currently loaded models
# dynamically, none of this is hardcoded here.
service_openwebui() {
    TOTAL=$((TOTAL+1))
    local ui_port=8080 router_port=18881 host=127.0.0.1
    local ui="http://$host:$ui_port/"

    local marker="$STATE_DIR/openwebui_deliberately_off"
    local running=0
    pgrep -f "Open WebUI.app/Contents/MacOS/Open WebUI$" >/dev/null 2>&1 && running=1
    [ "$running" = "1" ] && rm -f "$marker"

    local cfg="" models_json=""
    if [ "$running" = "1" ]; then
        cfg=$(curl -s -m 3 "http://$host:$ui_port/api/config" 2>/dev/null)
        models_json=$(curl -s -m 3 "http://$host:$router_port/v1/models" 2>/dev/null)
    fi

    local name version
    name=$(json_field "$cfg" "name" "?")
    version=$(json_field "$cfg" "version" "?")

    local ok=0
    if [ -n "$name" ] && [ "$name" != "?" ]; then
        ok=1
        HEALTHY=$((HEALTHY+1))
    fi
    local owui_loaded_count=0
    if [ -n "$models_json" ]; then
        owui_loaded_count=$(printf '%s' "$models_json" | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(0); sys.exit(0)
print(sum(1 for m in d.get('data',[]) if (m.get('status') or {}).get('value')=='loaded'))
" 2>/dev/null)
        [ -z "$owui_loaded_count" ] && owui_loaded_count=0
    fi
    app_state_sf "$ok" "$running" "Open WebUI" "$marker"
    local owui_label="$STR_OWUI_LABEL"
    if [ "$owui_loaded_count" -eq 1 ]; then owui_label="$STR_OWUI_LABEL $(printf "$STR_COMMON_COUNT_PAREN" "1" "$STR_UNIT_MODEL_ONE")"
    elif [ "$owui_loaded_count" -gt 1 ]; then owui_label="$STR_OWUI_LABEL $(printf "$STR_COMMON_COUNT_PAREN" "$owui_loaded_count" "$STR_UNIT_MODEL_MANY")"; fi
    add "$owui_label | sfimage=$APP_SF"
    note_top_sf "$APP_SF" "$STR_OWUI_LABEL"

    # --- Actions ---
    if [ "$ok" = "1" ]; then
        add "--$STR_COMMON_OPEN | href=$ui"
    elif [ "$running" = "1" ]; then
        add "--$STR_COMMON_OPEN | bash=$SWIFTBAR_DIR/helpers/openwebui_open.sh terminal=false refresh=true"
    else
        add "--$STR_COMMON_STARTEN | bash=$SWIFTBAR_DIR/helpers/openwebui_open.sh terminal=false refresh=true"
    fi
    if [ "$running" = "1" ]; then
        add "--$STR_COMMON_RESTART | bash=$SWIFTBAR_DIR/helpers/openwebui_restart.sh terminal=false refresh=true"
        add "--$STR_COMMON_BEENDEN | bash=$SWIFTBAR_DIR/helpers/openwebui_quit.sh terminal=false refresh=true"
    fi
    if [ "$owui_loaded_count" -eq 1 ]; then
        add "--$STR_COMMON_UNLOAD_ONE | bash=$SWIFTBAR_DIR/helpers/llama_router_unload_all.sh param1=$router_port terminal=false refresh=true"
    elif [ "$owui_loaded_count" -gt 1 ]; then
        add "--$STR_COMMON_UNLOAD_MANY | bash=$SWIFTBAR_DIR/helpers/llama_router_unload_all.sh param1=$router_port terminal=false refresh=true"
    fi

    # --- Separator + info (models listed flat, no extra parent item -
    # clicking a loaded model directly unloads it, there is no separate
    # "Unload" sub-item anymore) ---
    add "$SEP"
    if [ "$ok" = "1" ]; then
        # Only loaded models are shown - unloaded ones add no value here
        # and were removed on request.
        local rows
        rows=$(printf '%s' "$models_json" | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for m in d.get('data',[]):
    st=(m.get('status') or {}).get('value','?')
    if st != 'loaded': continue
    args=(m.get('status') or {}).get('args',[]) or []
    mport = args[args.index('--port')+1] if '--port' in args else ''
    print(f\"{m.get('id','?')}|{mport}\")
" 2>/dev/null)
        local owui_llama_build=""
        if [ -z "$rows" ]; then
            add "--$STR_COMMON_NO_MODELS_LOADED | size=11"
        else
            while IFS='|' read -r mid mport; do
                [ -z "$mid" ] && continue
                add "--$(printf "$STR_COMMON_CLICK_TO_UNLOAD" "$mid") | size=11 bash=$SWIFTBAR_DIR/helpers/llama_router_unload.sh param1=$router_port param2=$mid terminal=false refresh=true"
                if [ -n "$mport" ]; then
                    local mprops; mprops=$(curl -s -m 3 "http://$host:$mport/props" 2>/dev/null)
                    local caps_lines
                    caps_lines=$(printf '%s' "$mprops" | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
mod=d.get('modalities',{})
caps=d.get('chat_template_caps',{})
labels=['$STR_CAP_TEXT']
if mod.get('vision'): labels.append('$STR_CAP_VISION')
if mod.get('audio'): labels.append('$STR_CAP_AUDIO')
if mod.get('video'): labels.append('$STR_CAP_VIDEO')
if caps.get('supports_tools'): labels.append('$STR_CAP_TOOLS')
for l in labels: print(l)
" 2>/dev/null)
                    while IFS= read -r rline; do
                        [ -z "$rline" ] && continue
                        add "----$rline | size=11"
                    done <<< "$caps_lines"
                    # Every model the router starts runs the same llama.cpp
                    # binary - one build number is enough, no need to repeat
                    # it per model, so only capture it from the first one.
                    if [ -z "$owui_llama_build" ]; then
                        owui_llama_build=$(json_field "$mprops" "build_info" "")
                    fi
                fi
            done <<< "$rows"
        fi
        local owui_ver_line; owui_ver_line=$(printf "$STR_COMMON_VERSION" "$version")
        local owui_latest; owui_latest=$(owui_latest_version)
        if [ -n "$owui_latest" ] && [ "$owui_latest" != "$version" ]; then
            owui_ver_line="$owui_ver_line $(printf "$STR_OWUI_UPDATE_AVAILABLE" "$owui_latest")"
        fi
        add "--$owui_ver_line | size=11"
        [ -n "$owui_llama_build" ] && add "--$(printf "$STR_OWUI_LLAMA_VERSION" "$owui_llama_build") | size=11"
    fi
}
