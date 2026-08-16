---
name: terse-skill-writing
description: Use when writing or editing a SKILL.md description (frontmatter) or a project/memory-style reference file — in a plugin, as a Cowork-side skill, or as a Claude Code memory file. These load in full every turn (SKILL.md descriptions) or on trigger (memory), so verbosity is a measurable latency cost, not a style question. Does NOT apply to dense technical reference (selectors, API parameters, config values, decision+rationale for a live project) — that is not verbosity; leave it alone.
---

# Write skills and memory notes tersely

**SKILL.md description:** what it does + a terse trigger list. Do not restate the same trigger in
three sentences; do not repeat ALWAYS in run-on sentences.

**Memory / summary notes:** record the current, valid conclusion. Do not keep the full
investigation log — when a theory is disproved, cut its supporting evidence out instead of
layering a correction on top.

**Exception:** an active project's dense technical reference (DOM selectors, API parameters,
config values, decision+rationale) is not verbosity — it would be expensive to rediscover, and it
is already dense per byte. Do not compress it.

**Why it matters:** a long Claude Code / Cowork session can easily burn tens of millions of
cache-read tokens — much of it fixed system-prompt content (skill descriptions, memory) that is
re-read on every turn. 2026-08-14: one real session used 102M cache-read tokens in ~3.75 hours;
that is what motivated this rule on both the CLI side (`~/.claude/CLAUDE.md`) and the Cowork side.
