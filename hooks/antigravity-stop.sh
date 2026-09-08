#!/usr/bin/env bash
# Antigravity Stop-hook adapter for the `hey` attention beep.
# Antigravity's payload is camelCase (conversationId, not session_id) and its
# Stop hook contract REQUIRES a JSON reply on stdout ({"decision": ...}) or
# the turn stays blocked — unlike Claude/Codex/Hermes, which just want exit 0.
# So this translates the id, fires hey.sh fire-and-forget (never delays the
# reply), and answers immediately.
src="${BASH_SOURCE[0]:-$0}"
while [ -h "$src" ]; do d="$(cd -P "$(dirname "$src")" && pwd)"; src="$(readlink "$src")"; [ "${src#/}" = "$src" ] && src="$d/$src"; done
HOOK_DIR="$(cd -P "$(dirname "$src")" && pwd)"

payload="$(cat)"
sid="$(printf '%s' "$payload" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("conversationId",""))' 2>/dev/null)"

if [ -n "$sid" ]; then
  ( printf '{"session_id":"%s"}' "$sid" | "$HOOK_DIR/hey.sh" ) >/dev/null 2>&1 &
fi

printf '{"decision":"stop"}\n'
exit 0
