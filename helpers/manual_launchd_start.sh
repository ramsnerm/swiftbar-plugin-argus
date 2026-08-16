#!/bin/bash
# One-time manual start of a launchd job's underlying program, WITHOUT
# registering it with launchd - used when the job has been permanently
# deactivated (bootout) but the user wants to run it once anyway, e.g. to
# test something before deciding to Activate it properly. Replicates
# ProgramArguments/WorkingDirectory/EnvironmentVariables/StandardOutPath/
# StandardErrorPath from the plist so behavior matches what launchd
# itself would have done - just without KeepAlive/RunAtLoad management.
plist="$1"
[ -z "$plist" ] && exit 1

json=$(plutil -convert json -o - "$plist" 2>/dev/null)
[ -z "$json" ] && exit 1

prog_args=()
while IFS= read -r line; do
    prog_args+=("$line")
done < <(printf '%s' "$json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for a in d.get('ProgramArguments',[]):
    print(a)
" 2>/dev/null)
[ "${#prog_args[@]}" -eq 0 ] && exit 1

env_vars=()
while IFS= read -r line; do
    env_vars+=("$line")
done < <(printf '%s' "$json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for k,v in (d.get('EnvironmentVariables') or {}).items():
    print(f'{k}={v}')
" 2>/dev/null)

workdir=$(printf '%s' "$json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('WorkingDirectory') or '.')" 2>/dev/null)
stdout_path=$(printf '%s' "$json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('StandardOutPath') or '/dev/null')" 2>/dev/null)
stderr_path=$(printf '%s' "$json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('StandardErrorPath') or '/dev/null')" 2>/dev/null)

cd "$workdir" || exit 1
env "${env_vars[@]}" nohup "${prog_args[@]}" >> "$stdout_path" 2>> "$stderr_path" &
disown
