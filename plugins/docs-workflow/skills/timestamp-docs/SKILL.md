---
name: timestamp-docs
description: Use when creating or editing a durable markdown reference document that describes state/architecture/configuration (data file, plan file, schema doc, index) — add or refresh its date stamp. Does NOT apply to one-off code files, throwaway scripts, log files, or chat replies.
---

# Date stamps on reference documents

## Why

Two sources will always drift apart. In one 2026-07-26 incident, an uploaded doc overwrote
several newer facts that had been verified in chat, because there was no way to tell at a glance
which was more recent. The date stamp fixes this: every state-describing document shows when it
was last updated.

## The format

In the header of data files and plan files, directly under the title:

```markdown
# <Title>

> **Status: YYYY-MM-DD** · Where the data comes from (e.g. "from a live query").
> Related: [`other_file.md`](other_file.md)
> Contains no secrets.
```

This is the same header the `project-docs` skill prescribes — do not invent another one, and do
not add a second date line.

## What to do

- **New document:** add the header with today's date.
- **Editing an existing document:** ALWAYS set the date to today. If you modify only one section
  and the rest comes from an older measurement, you may add an inline date to that section
  (e.g. "measured: 2026-08-01") — finer granularity than the header date alone.
- **Log files need no header date** — every entry carries its own date, and old entries are never
  rewritten.
- **When two sources disagree about the same thing** (e.g. an uploaded doc vs. what you verified
  in chat): check both dates and by default trust the newer one. **But a fact verified live always
  beats any doc's date.** If the dates are close and the content conflicts, ASK before overwriting
  anything — do not guess silently.
- **Skill files** (SKILL.md): if a skill hardcodes concrete, time-varying facts (ports, IPs,
  versions), the right fix is to **remove them and reference the data file** — the skill holds the
  rule, not the snapshot. If concrete data must stay anyway, add a "Last verified: YYYY-MM-DD"
  line next to it.

## When NOT needed

- Code files, scripts — git history is the version control there.
- One-off chat replies and analyses — not durable reference documents.
- Purely methodological docs that describe no state.

## Example

Input: "Update <project>_data.md, we now have 7 data sources."
Right move: alongside the content update, set the header's `**Status:**` date to today — do not
touch only the body text.
