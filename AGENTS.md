# hey

Attention beeps for terminal agents. When an agent hands back to you — a finished reply, or a
permission prompt — `hey` plays a short sound, **but only if you have been idle longer than a
threshold**. A fast back-and-forth stays silent; you are summoned only when you have likely stepped
away. Built for Claude Code hooks, but the CLI works anywhere.

**It never listens.** Most alerts are plain sounds; one is a short pre-rendered voice clip, because
a spoken word cuts through ambient audio better than a blip.

The rule is uniform and carries no model judgement: any hand-back beeps if and only if
`now − last_prompt ≥ threshold`. That rule is the product — changing it changes what the tool is.

**Open source, AGPL-3.0, passively maintained.** The public `README.md` is the user documentation
and stays that way; `CONTRIBUTING.md` and `LICENSING.md` carry the contribution and licensing
terms.

## Crew

The roles this project is worked by, and what each one needs. **No personas live here** — an agent
arrives already knowing who it is, and reads this project to learn the project.

| Role | What this project needs from it |
|------|---------------------------------|
| Engineering | The `hey` CLI, the hook scripts, the sound set |
| Code review | Any change to the idle gate. It is the whole behavioural contract |
| Content | The README is public OSS documentation, not internal notes |
| Sysadmin | Branch protection and the LGTM gate |

No architect or data role is in use.

**After any context loss, re-read your anchor under `~/.agent-anchors/hey/`** (canon §17). None
exists yet.

## Key files

- `README.md` — user documentation: install, use, hook wiring
- `hey` — the CLI
- `hooks/` — `turn-mark.sh` stamps the turn start; `hey.sh` decides and plays
- `assets/` — the sounds
- `config.sh` — defaults
- `MEMO-CODEX-URGENT.md` — untracked and open: LGTM gate and branch protection
