---
description: " "
argument-hint: "ping | chirp | knock | coin | chime | yourturn  [times]  [idle-seconds]  |  off"
allowed-tools: Bash(hey:*), Bash(hey), Bash(hey off)
---
Activate **hey** for THIS session only — a short **sound** plays when I hand back to you
(finish a reply, or hit a permission prompt), but **only if you've been idle longer than
the threshold**. Fast back-and-forth stays silent; you're beeped only when you've likely
stepped away. It plays on the machine where you sit (local, or forwarded if I'm driven
over SSH). Nothing listens, ever. Most alerts are plain sounds; `yourturn` is a
short pre-rendered voice clip.

Requested: `$ARGUMENTS`

## If `$ARGUMENTS` is empty
Do NOT pick a sound. Show the options and ask which they want — nothing else.

| Sound | Character |
|-------|-----------|
| ping  | one clean bright blip |
| chirp | two-note rising pip |
| knock | two soft low thumps |
| coin  | jaunty pickup blip |
| chime | Nina's sparkle arpeggio (the speech cue) |
| yourturn | a voice saying "your turn" — cuts through ambient audio |

Call format: `/hey <sound> [times] [idle-seconds]`. Defaults: times=1, idle-threshold=45s.

## If `$ARGUMENTS` is `off` / `stop`
Run `hey off`, confirm once. Nothing else.

## Otherwise — a sound, optionally times and threshold
Run `hey $ARGUMENTS` (e.g. `hey knock 2 45`). It previews the sound once and activates.
Confirm in one line: which sound, how many plays, and the idle threshold. Nothing more —
no meta narration on later turns.

## Notes
- Uniform rule, no model judgement: any hand-back beeps iff `now − last_prompt ≥ threshold`.
- Standalone tool at `~/42labs/john-w-bsmt/hey` (repo `4242labs/hey`); sounds in `~/42labs/john-w-bsmt/hey/assets/`.
- Independent of `/nina` voice — you can run either or both.
