---
name: project-docs
description: 'A lean project documentation system: one data file, one plan and one log per project, in a plain markdown vault. Use when creating, editing, reorganizing or archiving docs, or starting a new project. Triggers: "write the doc", "update the project info", "archive this", "new project", "update the log", documenting after a live system survey.'
---

# Project documentation

This system exists so that a year from now you can still tell **which information is true** and
**why things ended up the way they did** — with as little context as possible. Every rule serves
that.

## Folder structure

Everything lives in your docs folder — `~/YourVault` below (e.g. an Obsidian vault). Each project
is one folder under it. Subprojects live under the main project's folder, in their own folder.

```
~/YourVault/
  projects.md                index: which projects exist, what each is about
  shared/                    knowledge spanning several projects (see The shared layer)
  data/                      symlinks to EVERY data file (see Mirroring)
  archive/                   common archive (see Archive)
  <project>/
    <project>_data.md        1 — data
    <project>_plan.md        2 — plan / process
    <project>_log.md         3 — log
    <misc>/                  artifacts: .sql, .mermaid, .py, .skill, images
    <subproject>/
      <subproject>_data.md
      <subproject>_plan.md
      <subproject>_log.md
```

**File name = folder name + `_data` / `_plan` / `_log`.** No exceptions. The name is unambiguous
on its own, so it stays recognizable in the mirror folder and in an open editor tab.

**Exactly one data file, one plan and one log per project and per subproject.** If a data file
grows unmanageably large, that does not mean more data files — it means a **subproject should be
split off**. (For a large main project a thematic data file — `<project>_data_<topic>.md` — is
allowed if the topic is a self-contained data set with no plan/log of its own.)

**A subproject is warranted only if it has a life of its own:** its own plan and its own log. If
it is data only, it is a section in the main project's data file, not a separate folder.

## One story — one place

The **detailed** account of an event or decision lives only in the log. The data file and the plan
may reference it by date at most ("see log 2026-08-15") — they do not retell it. If the same story
is written out in two files, one of them must be deleted.

## Workbench — `~/YourVault-workbench/`

A sibling folder next to the vault, outside it. Everything **in progress** goes here: scripts
being written, exploratory files, packages being prepared for publication — in per-project
subfolders. It is not part of your docs git repo; git-sync tooling must not commit it. When a
piece of work is finished and goes under version control, it **moves out**: either into the right
project folder in the vault, or into its own repo. Data files do not live in the workbench —
confirmed knowledge goes to the vault.

## The shared layer — `shared/`

Not a project, so it has no plan and no log — only data files. Knowledge that **spans several
projects** and therefore belongs in no single project folder goes here, e.g.:

```
shared/
  shared_data_infrastructure.md   your environments, what goes where, domains, public access
  shared_data_access.md           SSH keys, git repos, where secrets live, bots, time zones
  shared_data_network.md          router / AP / switch operating rules
```

**The test:** if a fact would be true in two projects and you would write it into both — it
belongs in `shared/`, and the project docs **reference** it. If it is true in only one project, it
stays there.

A new topic file is warranted only when a fact fits none of the existing ones. Do not pre-create
empty skeletons: `shared/` files are data files too, so they may contain only confirmed facts.

## The three file types

### 1. `<project>_data.md` — data

Only **current, confirmed** facts. This file contains data and nothing else.

- When a value, parameter or setting changes: **delete the old, write the new.** No commentary,
  no "this used to be".
- **No historical references.** No old IPs, no past migrations, no "was X, now Y". Whoever wants
  the story opens the log.
- **No explanations or teaching.** A data file states, it does not lecture. Operational lessons,
  pitfalls, "careful, because…" → the plan's **Notes** section. At most one line of qualification
  per fact; format: tables or `key: value`, not paragraphs.
- **No plans.** "Still needs doing" goes to the plan file.
- Every statement should come from a **live check**, not from an earlier document. Mark what you
  could not verify — or leave it out.
- If a number is the result of a measurement, note the measurement date.

Mandatory header:

```markdown
# <Title>

> **Status: YYYY-MM-DD** · Where the data comes from (e.g. "from a live query").
> Related: `<other file>.md`, `<other file>.md`
> Contains no secrets.
```

### 2. `<project>_plan.md` — plan / process

- **Where we are** — the current process in keywords: done, in progress, blocked. Not prose —
  bullets, one line each.
- **The plan — current** — next steps in order. One or two lines per item; the rationale belongs
  to the log.
- **Plan B — long term** — what comes later.
- **Notes** — the "when X, don't forget Y" pitfalls and operational warnings. This is dense
  technical reference — do not compress it further.

This file is about **open** work. **What is finished is deleted from here in the same pass** — it
may not stay even struck through or marked "DONE". The story belongs to the log; if a closed item
leaves an open remainder, that lives on as a new item.

### 3. `<project>_log.md` — log

When we changed what, and **why**. This is the only place where the story lives.

- **Newest entry on top.**
- One entry = `## YYYY-MM-DD — <what>`, then briefly: what we did, **why**, and the outcome. If a
  decision was made, its rationale goes here too.
- Old entries are never rewritten or deleted — **but they are compacted**: for entries older than
  14 days, **one line** stays in the live log (`- YYYY-MM-DD — what + key outcome`) and the full
  text moves **unchanged** to `archive/<project>_log_archive.md` (newest on top). The one-liners
  sit at the end of the log in a "Compacted history" section, in descending date order.
- Every substantive change gets a log entry **in the same pass** as the data file or plan edit.
  Left for a later round, it never happens.

### 4. `archive/` — the archive

Not a file type but a **shared folder** in the vault root. Two things go here:

- **A discontinued or merged file**, named `YYYY-MM-DD_<original filename>.md` (suffix `_2`, `_3`
  on collision). If only the data changed, you edit the data file and log it — you do not archive
  a copy. The archive is not version control (git is).
- **`<project>_log_archive.md`** — the full text of compacted log entries, newest on top.

We never work from the archive and never load it into context. No live file references it — the
**single exception** is the log's "Compacted history" section pointing at its own log archive.

## Mirroring

Every data file gets a symlink in `data/`, so it is reachable from any project:

```bash
ln -sfn ../<project>/<project>_data.md  ~/YourVault/data/<project>_data.md
ln -sfn ../<project>/<subproject>/<subproject>_data.md  ~/YourVault/data/<subproject>_data.md
```

**Symlink, not copy** — there is one physical file, so nothing can drift apart. Only data files
are mirrored; plans and logs are project-internal.

## Secrets

Passwords, tokens, private keys and API keys go into **no file whatsoever**, and not into the chat
either. They live in your password manager (e.g. Vaultwarden) and in the machines' `.env` files. A
doc may at most say **where** they are (e.g. "the token is in `/opt/<app>/.env`") and what each
key is called.

The data file header states: `Contains no secrets.`

## Working method

When you write or update documentation:

1. **Verify live**, do not work from the docs. SSH, `systemctl`, `SHOW COLUMNS`, `curl` — an old
   doc's claim is not a source.
2. **Data → data file, open work → plan, what happened → log.** If in doubt: still true in a
   year → data; needs doing → plan; done → log.
3. **Date stamp** in the data file and plan headers, refreshed on every edit.
4. **Log entry in the same pass.** A closed plan item is deleted from the plan in that same pass.
5. **Compaction:** if the live log holds a full entry older than 14 days, move it to the log
   archive and leave a one-liner.
6. If a file is discontinued or merged, **archive** it under the name above, and update the
   `projects.md` index and the `data/` symlinks.

## Never do this

- No "(previously 10.0.0.43)"-style parenthetical remarks in a data file.
- No explanations in a data file — data states; lessons go to the plan's Notes section.
- No closed or struck-through items left in the plan.
- Never write the same story out in two files — details belong to the log, the rest reference it.
- Never keep two live files on one topic. One topic = one live document.
- Never copy data from one data file into another — reference it.
- Never put a command block meant to be runnable into a data file without having verified it on
  that machine. A pre-written command in a doc is a sketch, not a source.
- Do not archive on every edit. The archive is not version control.
