#!/bin/bash
# All user-visible text for Argus in one place - menu labels, action
# names, info lines, and notification texts. Change/translate here,
# nothing else needs touching. Sourced by argus.30s.sh and by every
# helper script that shows its own notification.
#
# Naming: STR_<SCOPE>_<PURPOSE>, where SCOPE is either a service
# short-name or COMMON/UNIT/CAP/FOOTER/NOTIFY for shared/global text.
# Names describe the UI PURPOSE, not the German wording, so they stay
# meaningful after translation. "%s" placeholders are filled with
# printf, e.g.: printf "$STR_COMMON_VERSION" "$version"

# --- Shared across (almost) every service ---
STR_COMMON_OPEN="Öffnen"
STR_COMMON_START="Start"
STR_COMMON_STARTEN="Starten"
STR_COMMON_STOP_TEMP="Stopp (temporär)"
STR_COMMON_RESTART="Neustart"
STR_COMMON_BEENDEN="Beenden"
STR_COMMON_ACTIVATE_PERMANENT="Aktivieren (dauerhaft)"
STR_COMMON_DEACTIVATE_PERMANENT="Deaktivieren (dauerhaft)"
STR_COMMON_LOG_OPEN="Log öffnen"
STR_COMMON_UPDATE_TO="Update auf %s"
STR_COMMON_VERSION="Version: %s"
STR_COMMON_EXTERNAL="External: %s"
STR_COMMON_HTTP_SUFFIX=" (HTTP %s)"
STR_COMMON_NO_MODELS_LOADED="keine Modelle geladen"
STR_COMMON_UNLOAD_ONE="Modell entladen"
STR_COMMON_UNLOAD_MANY="Alle Modelle entladen"
STR_COMMON_CLICK_TO_UNLOAD="%s (zum Entladen klicken)"
STR_COMMON_COUNT_PAREN="(%s %s)"

# --- Model-count unit words (singular/plural) ---
STR_UNIT_MODEL_ONE="Modell"
STR_UNIT_MODEL_MANY="Modelle"

# --- Model capability labels (Open WebUI / llama.cpp router) ---
STR_CAP_TEXT="Text"
STR_CAP_VISION="Vision"
STR_CAP_AUDIO="Audio"
STR_CAP_VIDEO="Video"
STR_CAP_TOOLS="Tools"

# --- MCP Proxy ---
STR_MCP_LABEL="MCP Proxy"
STR_MCP_LABEL_COUNT="MCP Proxy: %s/%s"
STR_MCP_CONFIGURE="MCPs konfigurieren"
STR_MCP_NO_SERVERS="keine MCP-Server in server.json"
STR_MCP_NOT_CHECKABLE="nicht prüfbar (Proxy aus)"
STR_MCP_CLAUDE_CONNECTION="Claude Verbindung (%s)"
STR_MCP_CLAUDE_CONNECT_SUFFIX="(verbinden)"
STR_MCP_CLAUDE_DISCONNECT_SUFFIX="(trennen)"

# --- ComfyUI ---
STR_COMFY_LABEL="ComfyUI"
STR_COMFY_RENDERING_SUFFIX=": rendert"
STR_COMFY_UPDATE="Update (%s)"
STR_COMFY_QUEUE="Queue: %s aktiv · %s wartend"
STR_COMFY_MODEL_ROW="%s (%s, %s GB)"

# --- llama FIM ---
STR_FIM_LABEL="llama FIM"
STR_FIM_MODEL="Modell: %s"
STR_FIM_CONTEXT="Kontext: %s Token"

# --- Forgejo (Gitea MCP) ---
STR_GITEA_LABEL="Forgejo (Gitea MCP)"

# --- Home Assistant MCP ---
STR_HA_LABEL="Home Assistant MCP"

# --- Paste MCP ---
STR_PASTE_LABEL="Paste MCP"

# --- Search Mestro MCP ---
STR_SEARCHMESTRO_LABEL="Search Mestro"

# --- Open WebUI ---
STR_OWUI_LABEL="Open WebUI"
STR_OWUI_LLAMA_VERSION="Version integrated llama.cpp: %s"
STR_OWUI_UPDATE_AVAILABLE="(Update verfügbar: v%s)"

# --- Footer ---
STR_FOOTER_VERSION="Argus Version: %s"
STR_FOOTER_LAST_UPDATE="Letztes Update: %s"

# --- Notifications: aggregate service errors ---
STR_NOTIFY_ERROR_TITLE="Argus (SwiftBar Plugin): Fehler"
STR_NOTIFY_OK_TITLE="Argus (SwiftBar Plugin)"
STR_NOTIFY_OK_MESSAGE="Alle Dienste wieder ok"

# --- Notifications: misconfiguration (missing helper scripts) ---
STR_NOTIFY_MISCONFIGURED_TITLE="Argus (SwiftBar Plugin): falsch konfiguriert"
STR_NOTIFY_MISCONFIGURED_MESSAGE="Fehlende Helper-Skripte: %s"

# --- Notifications: MCP Proxy update helper ---
# No "already current" message - the Update button that triggers this
# script is itself only shown when a newer version was detected, so that
# case isn't reachable in normal use.
STR_NOTIFY_MCP_UPDATE_TITLE="Argus (SwiftBar Plugin): MCP Proxy Update"
STR_NOTIFY_MCP_UPDATE_DONE="v%s → v%s, neu gestartet"
STR_NOTIFY_MCP_UPDATE_FAILED="Update fehlgeschlagen (pip-Fehler)"

# --- Notifications: llama FIM update helper ---
STR_NOTIFY_FIM_UPDATE_TITLE="Argus (SwiftBar Plugin): llama FIM Update"
STR_NOTIFY_FIM_NO_BUILD="Kein Build gefunden"
STR_NOTIFY_FIM_BINARY_MISSING="%s gefunden, aber Binary fehlt"
STR_NOTIFY_FIM_UPDATE_DONE="%s → %s, neu gestartet"

# --- Notifications: ComfyUI update helper ---
STR_NOTIFY_COMFY_UPDATE_TITLE="Argus (SwiftBar Plugin): ComfyUI Update"
STR_NOTIFY_COMFY_PULL_FAILED="git pull fehlgeschlagen"
STR_NOTIFY_COMFY_UPDATE_DONE="%s → %s, neu gestartet"
