---
name: diy
description: At the end of a session where I had you do terminal/tooling/setup/investigation legwork, reconstruct the plain, human-runnable version of how I could have done it myself — the steps, the docs to read, the reasoning, and the commands a competent dev would actually type by hand (not your exact instrumented ones). A learning artefact to stop my terminal skills decaying. Run it via /diy, optionally naming which task to focus on (e.g. "/diy the R2 backup setup").
---

# DIY — how I could have done it myself

I get you to brute-force through tooling chores I could do myself but can't be bothered with. That's deliberate — but it's eroding my hands-on terminal skill. This skill reconstructs the session's work as a clean, runnable playbook *I* could follow, so I retain the knowledge even when I outsourced the doing.

## What to produce

Read back through the session (the whole thing, or just the task named in the argument if one is given). Work out what was actually achieved and the real path to it — investigation, decisions, commands, docs consulted, the gotchas that mattered. Then reconstruct the **streamlined path a competent dev would take by hand** to reach the same outcome.

This is not a transcript. It's the idiomatic version, rewritten for a human.

## The core rule: translate my commands into what a human would type

Strip the instrumentation I add for my own benefit and give the plain version:

- No `2>/dev/null`, `| cat`, `|| true`, defensive flags, or output suppression.
- No background-task wrappers, `&`, heredocs, or giant one-liners built to avoid a prompt.
- No decorative `echo "=== ... ==="` headings or progress scaffolding.
- No absolute-path-everything — use `cd` into the directory and relative paths like a person would.
- No `jq`/`awk`/`sed` acrobatics unless a human genuinely would reach for them; otherwise show the normal command.
- Prefer the **canonical, idiomatic invocation** the tool's own docs would show, with only the flags a competent dev would actually type. If I used a clever equivalent, give the obvious one — even if that's two plain commands instead of one fused one.
- Drop steps that were purely my own overhead: reading files through tools, re-checking state I'd clobbered, retries/corrections of my own mistakes.

## Include the conceptual steps too, not just commands

Many steps aren't commands. List them as steps anyway:
- "Read the docs for X at <url>" (include the actual link if I pointed you at it or you found it).
- "Open the Y dashboard, check Z."
- "Skim `man foo` / `foo --help` for the flag you need."
- "Decide between A and B because…"

For each step, give the **why** alongside the how: what you're trying to find out, what you're looking for in the output, and how the result picks the next step. That reasoning is the part that actually builds judgement — it's the point of the whole exercise.

## Calibration

Match my level (see global CLAUDE.md). Don't explain `cd`, `ls`, `git status`, or basic syntax. *Do* explain the non-obvious tool, flag, sequencing decision, or gotcha — inline and brief. Terse throughout; no fluff, no padding. If the session was trivial, the playbook should be trivial — don't inflate it.

## Honesty about what's reconstructed

These commands are reconstructions of the idiomatic human form, not necessarily the exact strings that ran. That's fine — but don't present a guessed command as verified. If you're unsure a reconstructed command would work as written (e.g. flag differs by version), say so in a word rather than implying it's confirmed.

## Output format

1. One line: the goal / outcome that was achieved.
2. Numbered steps. Each step:
   - **Bold action line** (what to do).
   - The command(s) in a fenced block (omit for purely conceptual steps).
   - A short *why* — calibrated, one or two sentences.
3. End with two short closers when they apply:
   - **Gotchas** — wrong turns or easy-to-miss steps that genuinely taught something (an auth step, an order dependency, a flag that didn't work). Keep the main path clean; park these here.
   - **Net:** roughly how many commands the whole thing actually was — so I can see how small it really was.

If the session covered several unrelated tasks and no focus was given in the argument, ask which one I want (or do them as separate segmented playbooks).

If I ask, save the playbook to a markdown file so I can keep it as a personal runbook; otherwise just print it.
