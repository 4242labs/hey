# hey

Attention beeps for terminal agents. When an agent hands back to you — a finished reply, or a
permission prompt — `hey` plays a short sound, **but only if you have been idle longer than a
threshold**. A fast back-and-forth stays silent; you are summoned only when you have likely stepped
away. Built for Claude Code hooks, but the CLI works anywhere.

**It never listens.** Most alerts are plain sounds; one is a short pre-rendered voice clip, because
a spoken word cuts through ambient audio better than a blip.

**The gate is uniform and carries no model judgement.** Once a session is armed with `hey <sound>`,
a hand-back beeps when `now − last_prompt ≥ threshold`. A missing turn marker counts as long-idle
and beeps: the design fails toward alerting rather than toward silence. That gate is the product —
changing it changes what the tool is.

**Beep where you sit.** Over SSH the beep sounds on *your* machine, not the remote box: `hey`
forwards the sound name over a multiplexed SSH forced-command call to `server/hey-play` on the
operator's machine. It fails closed — if the channel is down the beep is dropped, never sounded
into an unattended room.

**Open source, dual-licensed** — AGPL-3.0, commercial on request (`LICENSING.md`) — and passively
maintained. The public `README.md` is the user documentation and stays that way.

## How work flows

Branch, work from a worktree under `.worktrees/`, open a PR against `main`. The LGTM gate runs on
every PR. The `.claude/` CLU guards enforce worktree-only writes and refuse a self-merge, but only
while a CLU run is active. `main` is not branch-protected, so the gate is advisory.

## Crew

The roles this project is worked by, and what each one needs. **No personas live here** — an agent
arrives already knowing who it is, and reads this project to learn the project.

| Role | What this project needs from it |
|------|---------------------------------|
| Engineering | The `hey` CLI, the hook scripts, the reverse-beep path, the sound set |
| Code review | Any change to the idle gate or to the fail-closed reverse path. Both are the behavioural contract |
| Security review | Only when the SSH forced-command setup changes — it is a key-authorized remote execution path |
| Content | The README is public OSS documentation, not internal notes |
| Sysadmin | Branch protection and the gate |

No architect or data role is in use.

**After any context loss, re-read your anchor under `~/.agent-anchors/hey/`** (canon §17). None
exists yet.

## Key files

- `README.md` — user documentation: install, use, hook wiring, reverse-beep setup
- `hey` — the CLI
- `hooks/` — `turn-mark.sh` stamps the turn start; `hey.sh` decides and emits
- `server/hey-play` — the reverse-beep endpoint, run as an SSH forced command on the operator's machine
- `config.sh` — defaults and the reverse-beep destination resolution
- `assets/` — the sounds
- `MEMO-CODEX-URGENT.md` — untracked. Its gate item is done; branch protection is still open
