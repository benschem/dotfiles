# Global conventions

## Spelling

Use British/Australian English spelling everywhere — in code (identifiers, constants, comments), docs, commit messages, and prose. Examples: `sanitise` not `sanitize`, `honour` not `honor`, `colour`, `behaviour`, `initialise`, `cancelled`.

Exception: do not change spelling that is fixed by an external API, library, or standard (e.g. CSS `color`, HTTP headers, third-party method names like `serialize`). Match the upstream spelling when interfacing with it; use British spelling for everything you control.

## Git and commits

- Never commit, push, or open PRs. I do all the committing myself.
- Never credit yourself in a commit (no `Co-Authored-By`, no Claude/AI mentions).
- Never stage-and-commit in one move. Stage only when I ask, then stop so I can review and write the message myself.
- When I ask for a commit message, give me 5 different options. Match the style of recent commits — conventional prefixes (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).

## How I want to work

- When you explain or recommend something, give the *why*, not just the *what* — but don't force rationale onto a plain "do X".
- When there's more than one reasonable approach, present the options with pros/cons and a recommendation, then let me make the call. If there's genuinely only one sensible way, just take it — don't manufacture options to pad the list.
- Default to the conventional/idiomatic approach, and to tools, libraries, and code that already exist. Call it out when I'm reinventing the wheel — a stdlib/library/framework feature, or something already solved in the repo — and don't let me build it from scratch unless I've knowingly chosen to.
- I often drive work through a plan file (`PLAN.md` etc.) — "execute next step" and "update the plan" is the normal rhythm.

## Done means verified

- Verify when being wrong is expensive — code you changed, claims about how something behaves. Run it before calling it done. "Should work" is not done.
- Don't verify what can't really be wrong, and don't narrate the check. No re-reading a file you just wrote to confirm the write.
- If you can't run it, say so plainly and state what's unverified, rather than implying it's confirmed.

## Code style

- No single-letter variable or method names. Readability beats cleverness — I'll take boilerplate over magic (unless it's framework-conventional magic).
- Optimise for a stranger, or me in 12 months, trying to grok it cold.
- Comments explain *what* and *why*, but no comment soup. If a name needs a comment to justify it, the name is wrong — rename it.

## Writing (docs, README, prose)

- No tables in markdown — they render badly.
- README stays generic/vendor-neutral. Personal deploy specifics live in `DEPLOYMENT.md`, which is intentionally uncommitted — don't reference it from committed files.
