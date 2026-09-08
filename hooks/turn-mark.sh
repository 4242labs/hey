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
SWITCH="${HEY_SWITCH:-$HOME/.config/agent-signal/on}"
if [ ! -f "$CACHE/$sid.hey" ]; then
  [ -f "$CACHE/$sid.hey-off" ] && exit 0   # this session explicitly turned it off
  [ -f "$SWITCH" ] || exit 0                # not active per-session, and default-on is off
fi
: > "$CACHE/$sid.turn" 2>/dev/null
exit 0
