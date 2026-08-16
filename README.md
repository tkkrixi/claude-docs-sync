# claude-docs-sync

A working pattern for two unsolved problems in the Claude ecosystem:

1. **Keeping skills in sync between Claude Code (CLI) and Claude Desktop / Cowork** — there is no
   native sync ([#20697](https://github.com/anthropics/claude-code/issues/20697),
   [#50644](https://github.com/anthropics/claude-code/issues/50644),
   [#52421](https://github.com/anthropics/claude-code/issues/52421),
   [#53414](https://github.com/anthropics/claude-code/issues/53414),
   [#36693](https://github.com/anthropics/claude-code/issues/36693)).
2. **Keeping the AI's project knowledge lean** — markdown docs that every session loads as
   context, without letting them rot or bloat.

It is not magic: it is git as the single source of truth, one symlink, one packaging script, and a
documentation discipline encoded as Claude skills so the AI itself follows and maintains it.

## The sync pattern

```
                    ┌──────────────────────────────┐
                    │  git repo (single source)    │
                    │  your-docs-repo/             │
                    │    plugins/<your-plugin>/    │
                    └──────┬───────────────┬───────┘
             symlink, instant│             │package.sh → .plugin file
                             ▼             ▼
                  ┌────────────────┐   ┌─────────────────────────┐
                  │ Claude Code CLI│   │ Claude Desktop / Cowork │
                  │ ~/.claude/skills│  │ (manual upload, per     │
                  │   /<plugin> →  │   │  version — see below)   │
                  └────────────────┘   └─────────────────────────┘
```

| Step | Automatic? |
|---|---|
| Edit → repo (with a git auto-commit tool, e.g. obsidian-git) | yes, ~10 min |
| Edit → repo (without) | no — `git add/commit/push` |
| Repo → CLI | **yes, instant** (symlink) |
| Repo → Desktop/Cowork | **no** — run `package.sh`, upload the `.plugin` in the app |
| Desktop/Cowork edit → repo | no — export, copy back, commit |

Setup for the CLI side (one time, per machine):

```bash
ln -s /path/to/your-docs-repo/plugins/docs-workflow ~/.claude/skills/docs-workflow
```

Claude Code reads every subdirectory of `~/.claude/skills/`, so the symlink is all it takes —
every commit (and every uncommitted edit) is live in the next CLI session.

For the Desktop/Cowork side, `scripts/package.sh` validates the skills (frontmatter, names,
optional `claude plugin validate`) and zips the plugin into a `.plugin` file you upload in the
app. Two hard-won details it encodes:

- the output **filename must not contain the version** — Cowork derives the plugin name from the
  filename, so a versioned filename creates a *new* plugin instead of updating the existing one;
- bump `version` in `plugin.json` for every upload, and package from a clean git state so the
  archive copy (`dist/archive/<name>-<version>.plugin`) matches a commit.

Known limitation: the Desktop/Cowork copy is a snapshot in your Claude account. It does not watch
the repo — no poll, no webhook — and there is no documented programmatic way to update it. One
manual upload per version is currently the floor. Do **not** build tooling on the local session
cache (`~/Library/Application Support/Claude/local-agent-mode-sessions/...`): the path is
session-scoped and unstable.

## The documentation system

The `docs-workflow` plugin encodes a lean markdown knowledge base that AI sessions load as
context, so verbosity is a measurable token cost, not a style question:

- **`project-docs`** — one folder per project with exactly three living files: `_data.md`
  (current verified facts only — no history, no teaching), `_plan.md` (open work only — closed
  items are deleted the same session), `_log.md` (the only place history lives; newest first).
  Log entries older than 14 days are **compacted** to one line, full text moved to an archive
  file that is never loaded as context. "One story — one place": details live in the log, other
  files reference by date.
- **`knowledge-base-map`** — a template map of where knowledge lives, so the AI reads the right
  file instead of answering from memory. Fill in your own projects.
- **`security-checklist`** — a mandatory checklist for every infrastructure change (exposure,
  auth and secrets, brute-force, backup, reboot survival, monitoring), plus measurement
  discipline: negative claims only from valid probes, IPv4 and IPv6 checked separately.
- **`terse-skill-writing`** — skill descriptions and memory notes are loaded every turn; write
  them tersely. (Motivating incident: a single real session burned 102M cache-read tokens in
  ~3.75 hours, mostly re-reading fixed prompt content.)
- **`timestamp-docs`** — every state-describing doc carries a status date, so when two sources
  disagree you know which is newer; live verification always beats any doc.

The optional `homelab-extras` plugin adds **`own-infra-first`** (check your already-paid
environments before proposing any new SaaS) and **`proxmox-ha-new-guest`** (Proxmox HA is not
automatic: replication + HA resource + affinity + backup, and the bind-mount-blocks-pvesr
pitfall).

## Install

As a marketplace (CLI):

```
/plugin marketplace add <github-user>/claude-docs-sync
/plugin install docs-workflow@claude-docs-sync
/plugin install homelab-extras@claude-docs-sync   # optional, homelab users
```

Or clone and symlink (gets you the instant-sync editing loop described above). For
Desktop/Cowork: `bash scripts/package.sh` and upload `scripts/dist/docs-workflow.plugin` in the
app's plugin settings.

## Adapting it

Everything instance-specific is a placeholder (`~/YourVault`, `<node-a>`,
`your-domain.example`). Start by filling in `knowledge-base-map` for your own projects and
creating your vault with `projects.md`. The system works with any git host — self-hosted Gitea,
GitHub, GitLab — because nothing but plain git is required.

## License

MIT
