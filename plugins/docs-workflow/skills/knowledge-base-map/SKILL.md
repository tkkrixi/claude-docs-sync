---
name: knowledge-base-map
description: 'Map of the markdown knowledge base — says which document holds the answer. Use BEFORE stating anything about machines, network, servers, containers, or any project — systems overlap, and a question that looks like one project may be decided elsewhere. Triggers: "where are we with", "what runs on", "what IP does it have", "how do I reach it", "what was the decision", "where should this go".'
---

# Knowledge base — the map

> **TEMPLATE — fill this in for your own setup.** Replace the `<your-...>` placeholder rows and
> paths below with your real projects and files, then delete this note. The structure and the two
> rules at the bottom are the part worth keeping as-is.

Knowledge lives in **markdown files**, in a single source: your docs git repo (e.g. self-hosted
Gitea or a private GitHub repo), whose working copy on your machine is `~/YourVault` — your docs
folder, e.g. an Obsidian vault. The same content may also be uploaded to a claude.ai project
knowledge base.

**This file contains no data — it only says where the data is.** Before stating anything about
these systems, read the relevant file. Do not answer from memory.

## Where to reach it

| Environment | Path |
|---|---|
| Claude Code CLI on your machine | `~/YourVault/` — readable directly |
| Cowork / desktop | same path via the device bridge; if the device is unreachable, the project knowledge base |
| claude.ai chat | the documents of your claude.ai project |

Entry point is always `projects.md` (the index) — every file is reachable from there.

## The structure

```
~/YourVault/
  projects.md           index — what exists, where
  shared/               knowledge spanning several projects
  <your-infra-project>/ e.g. your own infrastructure / homelab
  <your-project-b>/     e.g. a product or client project
  data/                 symlinks to EVERY data file
  archive/              outdated — never work from here
```

Three roles per project: `*_data.md` (current facts), `*_plan.md` (what remains + the pitfalls),
`*_log.md` (when we did what, and why). If the question is "why did this end up this way", the
answer is in the log, not the data file.

## What to read for which question

| The question is about | Read this |
|---|---|
| What to install where, which environment can carry it | `shared/shared_data_infrastructure.md` |
| SSH keys, git repos, where secrets live, bots, time zones | `shared/shared_data_access.md` |
| Network gear — general operating rules | `shared/shared_data_network.md` |
| `<your-infra-project>`: machines, containers, services, backup, monitoring | `<your-infra-project>/<your-infra-project>_data.md` |
| `<your-infra-project>`: IP allocation, router, APs, switch | `<your-infra-project>/<your-infra-project>_data_network.md` |
| `<your-project-b>`: its domain-specific data | `<your-project-b>/<your-project-b>_data*.md` |
| How your plugin/skills sync between the CLI and desktop/Cowork | `<your-tooling-doc>.md` |

## Two rules that are easy to get wrong

**1. A live query beats the docs.** A document is a snapshot of one day. If the question prepares
an action (re-addressing, installing, HA, backup), verify live as well — SSH, `systemctl`,
`pvecm status` — and where they differ, the live state wins. State the discrepancy out loud, and
fix the doc.

**2. The systems overlap.** A question about one project is often answered in another project's
docs (e.g. its jobs run on your own infrastructure), and a client project may be governed by the
network rules in `shared/`. If a question touches two areas, read both — and knowledge that
clearly belongs to no single project goes into the `shared/` layer.

## If you write, not just read

The documentation rules — which file gets what, what the header looks like, when a log entry is
due, what archiving means — are in the `project-docs` skill. Follow it whenever you create or
modify a document.

The short version: **data → data file, what remains → plan, what happened → log**, date stamp on
every edit, and **secrets never go into a file** — passwords live in your password manager.
