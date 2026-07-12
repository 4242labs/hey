# hey — config. Override any var via env before calling `hey`.
# HEY_HOME is set by the `hey` script to its own dir (symlink-resolved); do not hardcode.

# Load machine-local overrides (gitignored).
[ -f "$HEY_HOME/.env" ] && set -a && . "$HEY_HOME/.env" && set +a

HEY_CACHE="${HEY_CACHE:-${TMPDIR:-/tmp}/hey-cache}"    # marker/scratch dir (never in-repo)
mkdir -p "$HEY_CACHE" 2>/dev/null
# Per-session token so concurrent agents isolate their markers + playback and
# never kill each other. Falls back to PID outside Claude Code.
HEY_SESSION="${HEY_SESSION:-${CLAUDE_CODE_SESSION_ID:-$$}}"
HEY_OUT="$HEY_CACHE/$HEY_SESSION"                       # markers: $HEY_OUT.hey / .turn

# --- sounds -------------------------------------------------------------------
HEY_DIR="${HEY_DIR:-$HEY_HOME/assets}"   # where the sounds live
HEY_THRESHOLD="${HEY_THRESHOLD:-45}"     # default idle seconds before a beep fires
HEY_TIMES="${HEY_TIMES:-1}"              # default number of plays per alert
HEY_GAP="${HEY_GAP:-0.25}"               # seconds between repeated plays
# One row per sound: "name|file". Names match case-insensitively.
hey_registry() {
  cat <<EOF
ping|$HEY_DIR/ping.wav
chirp|$HEY_DIR/chirp.wav
knock|$HEY_DIR/knock.wav
coin|$HEY_DIR/coin.wav
chime|$HEY_DIR/chime.wav
EOF
}
hey_menu() {  # just the names, one per line
  local name file
  while IFS='|' read -r name file; do [ -n "$name" ] && printf '%s\n' "$name"; done < <(hey_registry)
}
hey_lookup() {  # name -> file path on stdout (rc0); rc1 unknown
  local want name file
  want="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  while IFS='|' read -r name file; do
    [ -n "$name" ] || continue
    [ "$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')" = "$want" ] && { printf '%s' "$file"; return 0; }
  done < <(hey_registry)
  return 1
}

# --- cross-platform playback --------------------------------------------------
# afplay (macOS) | paplay/aplay (Linux, incl. WSLg). WSLg exposes a PulseAudio
# socket at /mnt/wslg/PulseServer — point paplay at it if unset.
[ -z "${PULSE_SERVER:-}" ] && [ -S /mnt/wslg/PulseServer ] && export PULSE_SERVER=/mnt/wslg/PulseServer
_hey_log() {  # message...   (opt-in: `touch ~/.cache/hey/debug.on`)
  [ -f "$HOME/.cache/hey/debug.on" ] || return 0
  mkdir -p "$HOME/.cache/hey" 2>/dev/null
  printf '%s [pid %s] %s\n' "$(date '+%H:%M:%S')" "$$" "$*" >> "$HOME/.cache/hey/hey.log" 2>/dev/null
}
_hey_playfile() {  # file
  if command -v afplay >/dev/null 2>&1; then
    local err rc
    err="$(afplay "$1" 2>&1)"; rc=$?      # plain afplay first (reaches the user's coreaudiod)
    if [ $rc -ne 0 ] && [ -n "${SSH_CONNECTION:-}" ] && command -v launchctl >/dev/null 2>&1; then
      err="$(launchctl asuser "$(id -u)" /usr/bin/afplay "$1" 2>&1)"; rc=$?
    fi
    _hey_log "playfile: afplay rc=$rc${err:+ err='$err'}"
    return $rc
  elif command -v paplay >/dev/null 2>&1; then paplay "$1"
  elif command -v aplay >/dev/null 2>&1; then aplay -q "$1"
  else echo "hey: no audio player found (afplay/paplay/aplay)" >&2; return 1
  fi
}
# Serialize playback machine-wide so overlapping alerts queue instead of colliding
# (macOS has no flock; use an atomic mkdir mutex).
_hey_play() {  # cmd args...   (e.g. _hey_play _hey_playfile file.wav)
  local lock="${TMPDIR:-/tmp}/hey.audiolock" i=0
  until mkdir "$lock" 2>/dev/null; do
    i=$((i+1)); [ "$i" -ge 300 ] && { rm -rf "$lock" 2>/dev/null; mkdir "$lock" 2>/dev/null; break; }
    sleep 0.1
  done
  "$@"
  rmdir "$lock" 2>/dev/null
}

# --- reverse-beep: sound where the operator sits, not on the calling box -------
# A beep is for a human, so it has to reach the machine the human is sitting at.
# Set HEY_TARGET on every box the operator does NOT sit at, and HEY_LOCAL=1 on the
# one they do (both via the gitignored .env) — then routing never depends on how the
# agent happened to be launched. SSH_CONNECTION is only a fallback for the interactive
# case; a daemon, a systemd unit or a re-attached tmux has none, and inferring from it
# alone silently drops the beep on an empty room.
# We forward only the sound NAME to the operator's `hey-play` forced command over a
# dedicated passphraseless key. Fails closed (drops the beep) so an unattended box
# stays silent rather than beeping to nobody.
HEY_TARGET="${HEY_TARGET:-}"                              # explicit host/IP; empty = auto from SSH origin
HEY_USER="${HEY_USER:-${USER:-$(id -un)}}"               # login on the operator's machine
HEY_KEY="${HEY_KEY:-$HOME/.ssh/id_hey}"                  # dedicated key (forced to hey-play on the far end)
_hey_ssh_opts=(-i "$HEY_KEY" -o IdentitiesOnly=yes
  -o ControlMaster=auto -o ControlPath="$HOME/.ssh/cm/%r@%h:%p" -o ControlPersist=4h
  -o ConnectTimeout=2 -o ServerAliveInterval=15 -o ServerAliveCountMax=2
  -o BatchMode=yes -o StrictHostKeyChecking=accept-new)
_hey_dest() {  # -> operator's host on stdout (rc0), or rc1 if the beep belongs here
  [ -n "${HEY_LOCAL:-}" ] && return 1       # we ARE the destination
  local host="$HEY_TARGET"
  [ -z "$host" ] && [ -n "${SSH_CONNECTION:-}" ] && host="${SSH_CONNECTION%% *}"
  [ -n "$host" ] || return 1                # nobody to forward to: single-machine setup
  printf '%s' "$host"
}
_hey_reverse() {  # sound times  -> 0 if the operator's machine accepted it
  local host
  host="$(_hey_dest)" || return 1
  [ -n "${1:-}" ] || return 1
  command -v ssh >/dev/null 2>&1 || return 1
  [ -f "$HEY_KEY" ] || return 1
  mkdir -p "$HOME/.ssh/cm" 2>/dev/null
  printf '%s %s\n' "$1" "${2:-1}" | ssh "${_hey_ssh_opts[@]}" "${HEY_USER}@${host}" hey-beep >/dev/null 2>&1
}
# THE routing decision. Every path that makes a sound goes through here — hand-back
# hook, `hey beep`, activation preview — so none of them can drift out of agreement
# and start beeping on the wrong box. Forward if the operator is elsewhere (dropping
# the beep if that channel is down); otherwise play right here.
_hey_emit() {  # sound [times]  -> play where the OPERATOR sits
  local file times i=0
  file="$(hey_lookup "${1:-}")" || return 1
  [ -f "$file" ] || return 1
  times="${2:-1}"; case "$times" in ''|*[!0-9]*) times=1 ;; esac
  if _hey_dest >/dev/null; then
    _hey_reverse "$1" "$times"; return $?
  fi
  while [ "$i" -lt "$times" ]; do
    _hey_play _hey_playfile "$file"; i=$((i+1))
    [ "$i" -lt "$times" ] && sleep "$HEY_GAP"
  done
  return 0   # the loop's last test is the gap check, which is false on the final
             # play — without this, a successful local beep reports failure.
}
