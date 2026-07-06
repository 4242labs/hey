#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook — stamp the start of a turn so hey's idle gate
# can measure how long you've been away. Only touches a marker for sessions where
# hey is active (a .hey file exists); no-ops for everything else. Pair with hey.sh.
sid=""
payload="$(cat 2>/dev/null)"
[ -n "$payload" ] && sid="$(printf '%s' "$payload" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null)"
[ -z "$sid" ] && sid="${CLAUDE_CODE_SESSION_ID:-}"
[ -z "$sid" ] && exit 0
CACHE="${HEY_CACHE:-${TMPDIR:-/tmp}/hey-cache}"
[ -f "$CACHE/$sid.hey" ] || exit 0   # hey not active for this session
: > "$CACHE/$sid.turn" 2>/dev/null
exit 0
