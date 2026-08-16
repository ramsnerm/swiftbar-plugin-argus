#!/bin/bash
# ============================================================ llama FIM ====
service_llama_fim() {
    TOTAL=$((TOTAL+1))
    local label="local.llama-fim-server" port=8012 host=127.0.0.1
    local log="$HOME/Library/Logs/llama-fim-server.log"
    local plist="$HOME/Library/LaunchAgents/$label.plist"

    launchd_info "$label"
    local props; props=$(curl -s -m 3 "http://$host:$port/props" 2>/dev/null)

    local sf="$SF_ERROR" label_txt="$STR_FIM_LABEL"
    local model="" ctx="" build=""
    if [ -n "$props" ]; then
        HEALTHY=$((HEALTHY+1))
        sf="$SF_OK"
        local model_path; model_path=$(json_field "$props" "model_path" "?")
        model="${model_path##*/}"
        ctx=$(json_field "$props" "default_generation_settings.n_ctx" "?")
        build=$(json_field "$props" "build_info" "?")
    elif [ "$LOADED" = "1" ] && [ -n "$PID" ]; then
        sf="$SF_STARTING"
    elif [ "$LOADED" = "0" ]; then
        sf="$SF_OFF"
    fi
    add "$label_txt | sfimage=$sf"
    note_top_sf "$sf" "$STR_FIM_LABEL"

    # Local-only check (no network): compare the build the launchd job
    # currently points at against the newest build Open WebUI has already
    # downloaded for itself - see llama_fim_update.sh for why this works.
    local fim_current fim_newest
    fim_current=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$plist" 2>/dev/null | grep -oE 'b[0-9]+' | head -1)
    fim_newest=$(ls -1 "$HOME/Library/Application Support/open-webui/llama.cpp" 2>/dev/null | grep -E '^b[0-9]+$' | sort -V | tail -1)

    # --- Actions ---
    local healthy=0; [ -n "$props" ] && healthy=1
    add_service_actions "$label" "$plist" "$healthy"
    add "--$STR_COMMON_LOG_OPEN | href=file://$log"
    if [ -n "$fim_newest" ] && [ "$fim_newest" != "$fim_current" ]; then
        add "--$(printf "$STR_COMMON_UPDATE_TO" "$fim_newest") | bash=$SWIFTBAR_DIR/helpers/llama_fim_update.sh terminal=false refresh=true"
    fi

    # --- Separator + info ---
    add "$SEP"
    if [ -n "$props" ]; then
        add "--$(printf "$STR_FIM_MODEL" "$model") | size=11"
        add "--$(printf "$STR_FIM_CONTEXT" "$ctx") | size=11"
        add "--$(printf "$STR_COMMON_VERSION" "$build") | size=11"
    fi
}
