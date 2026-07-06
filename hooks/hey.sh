#!/usr/bin/env bash
# Claude Code hook — the `hey` attention beep. Wire it on BOTH:
#   Stop         → agent finished a turn (an answer, or a prose question)
#   Notification → Claude Code needs you (permission prompt / idle input)
# Beeps ONLY when hey is active for this session ($HEY_OUT.hey, set by `hey <sound>`)
# AND you've been idle longer than the threshold — now - mtime(.turn) >= threshold.
# So a fast back-and-forth stays silent; you're summoned only when you've likely
# stepped away. Uniform rule for both hooks. The beep sounds where the OPERATOR
# sits: local when the agent runs there, else forwarded over the reverse channel
# (dropped, never sounded, if that box is unattended). Never blocks the turn.
src="${BASH_SOURCE[0]:-$0}"
while [ -h "$src" ]; do d="$(cd -P "$(dirname "$src")" && pwd)"; src="$(readlink "$src")"; [ "${src#/}" = "$src" ] && src="$d/$src"; done
HOOK_DIR="$(cd -P "$(dirname "$src")" && pwd)"
HEY_HOME="$(cd "$HOOK_DIR/.." && pwd)"

payload="$(cat)"
sid="$(printf '%s' "$payload" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null)"
[ -z "$sid" ] && sid="${CLAUDE_CODE_SESSION_ID:-}"
[ -z "$sid" ] && exit 0

export HEY_HOME HEY_SESSION="$sid"
. "$HEY_HOME/config.sh"               # defines HEY_OUT + helpers for THIS session

[ -f "$HEY_OUT.hey" ] || exit 0       # hey not active for this session

read -r sound times thresh < "$HEY_OUT.hey" 2>/dev/null
[ -n "$sound" ] || exit 0
times="${times:-$HEY_TIMES}"; thresh="${thresh:-$HEY_THRESHOLD}"
file="$(hey_lookup "$sound")" || exit 0
[ -f "$file" ] || exit 0

# Idle gate: seconds since your last prompt (turn-mark stamps .turn). Missing
# marker → treat as "long idle" and beep (fail toward alerting).
if [ -f "$HEY_OUT.turn" ]; then
  idle="$(python3 -c 'import os,sys,time;print(int(time.time()-os.path.getmtime(sys.argv[1])))' "$HEY_OUT.turn" 2>/dev/null)"
else
  idle="$thresh"
fi
[ -n "$idle" ] || idle="$thresh"
[ "$idle" -ge "$thresh" ] 2>/dev/null || exit 0

# Fire-and-forget so we never hold up Claude's turn. Beep where the operator is:
# reverse-forward when this box is driven over SSH (drop if that channel's down);
# otherwise play locally.
(
  if [ -z "${HEY_LOCAL:-}" ] && { [ -n "$HEY_TARGET" ] || [ -n "${SSH_CONNECTION:-}" ]; }; then
    _hey_reverse "$sound" "$times"
  else
    "$HEY_HOME/hey" beep "$sound" "$times"
  fi
) >/dev/null 2>&1 &
exit 0
