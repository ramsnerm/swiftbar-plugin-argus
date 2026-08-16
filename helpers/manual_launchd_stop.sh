#!/bin/bash
# Stops a launchd job's underlying process that was started manually via
# manual_launchd_start.sh (job is deactivated/not registered with
# launchd, so "launchctl kill" doesn't apply here - matches by the
# program's own binary path instead, same pattern used for the
# non-launchd apps Paste/Open WebUI).
plist="$1"
[ -z "$plist" ] && exit 1

prog=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$plist" 2>/dev/null)
[ -n "$prog" ] && pkill -f "$prog"
