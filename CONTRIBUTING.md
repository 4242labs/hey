# Contributing

**Status: passively maintained.** hey is used daily at 42labs and gets commits regularly —
but it is not a staffed product. There is no support rota and no SLA. Issues and pull
requests are welcome and genuinely read; expect a reply in weeks rather than days, and
sometimes not at all. That is capacity, not disinterest. Plan accordingly before you invest
a weekend.

## What's welcome

- **Bug reports with a reproduction.** Say which hook fired, what the idle threshold was, and whether it was local or over SSH.
- **Small, focused pull requests.** One logical change.
- **Documentation** — typos, unclear passages, missing setup steps. Always welcome, usually fast.

## What is unlikely to land

- Large refactors, architecture changes, rewrites.
- Features not discussed in an issue first. **Open the issue before you write the code** — one message, potentially a saved weekend.
- **Model judgement about when to beep.** The rule is uniform and deterministic: any hand-back beeps iff `now − last_prompt ≥ threshold`. That is the design, not a placeholder for something smarter.
- Speech, listening, or anything beyond a short sound. That is [johnny](https://github.com/4242labs/johnny)'s job.

## If you need it faster

Fork it. The AGPL-3.0 grants you exactly that. A fork that moves faster than this repo is
a good outcome, not a betrayal — this is a real answer, not a brush-off.

## Before you open a PR

There is no automated test suite — hey is shell, and what it does is make a noise at the
right moment. Exercise what you touched by hand, and say in the PR what you ran:

```bash
hey                  # the sounds list
hey knock 2 45       # <sound> [times] [idle-threshold-s] — previews once, then goes active
hey off              # stops cleanly
```

Then wire it into a real agent session and confirm the **idle gate** still holds: a fast
back-and-forth must stay silent, and a genuine walk-away must beep. That gate is the whole
product; a change that beeps on every turn is a regression even when nothing errors.

If you touched forwarding, test it over SSH. It fails closed by design — so a regression
there is not a crash, it is a beep that never sounds, in a room you are not in.

If you changed the bundled sounds, regenerate them with `assets/generate.py` (pure stdlib,
no deps) and commit the results.

## Licensing

hey is dual-licensed: AGPL-3.0 for open source, commercial terms on request — see
[LICENSING.md](LICENSING.md).

**By submitting a pull request you grant 42labs the right to distribute your contribution
under both the AGPL-3.0 and 42labs' commercial license.** You keep the copyright to what
you wrote. Without this grant a single merged patch would make the commercial half
unsellable, and we would have to refuse it.
