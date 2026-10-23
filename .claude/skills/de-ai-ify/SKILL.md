---
name: de-ai-ify
description: >-
  Manually invoked only (via /de-ai-ify). Edits a prose or markdown document so
  it stops reading as AI-generated and stops cluttering the raw view. Do not
  trigger automatically from related phrasing — run only when explicitly invoked.
---

# de-ai-ify

Make a document read as something a real person wrote, and read cleanly in raw
form (editor, terminal, diff) where markdown isn't rendered. This is editing,
not rewriting: preserve the author's meaning, structure, and voice. Remove the
tells; don't flatten the prose into a blander tell of its own.

Operate on the file or section the user points at — that invocation is your
go-ahead to edit directly, then report. If they scope it ("just the last
paragraph"), stay inside that scope.

First, pull the current tell list:
WebFetch https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing and ask
for the specific words, phrasings, and punctuation habits it flags. It changes
over time, so fetch it each run rather than working from memory.

Then make three passes:

1. **Strip decorative markup.** Remove `**bold**` and `*italic*` markers; keep
   backtick code spans and literal code with asterisks (`attr_*`, `2 ** 8`).
   For a whole file:
   `perl -0pi -e 's/\*\*//g; s/(?<!\*)\*(?!\*)([^*\n]+?)\*(?!\*)/$1/g' FILE.md`
   then `grep -n '\*' FILE.md` to confirm only intentional asterisks remain.
   Check for literal `**` operators outside backticks first; if present, edit
   by hand.

2. **Thin out em-dashes** — the strongest structural tell, and selective work,
   not wholesale. Convert dashes that just join two independent clauses to a
   period/colon/comma ("come back — it'll make sense" → "come back. It'll make
   sense."). Keep dashes doing real work: appositives, sharp contrasts, titles,
   parentheticals. Don't strip them all; zero em-dashes where the prose wants
   one is its own tell.

3. **Swap inflated vocabulary** for the plain word a person would say
   (belabour → dwell on, comprehension → understanding). Only swap words
   actually doing the tell — leave precise or idiomatic words alone even if
   slightly formal (bespoke, honour, domain jargon).

If a doc or section is already clean, say so rather than inventing edits to
look productive. Terse, opinionated, fragment-heavy engineering prose often has
nothing to fix.

When done, report what changed and what you deliberately kept and why — the
"kept" half shows the edits were judgement, and lets the author overrule a call.
