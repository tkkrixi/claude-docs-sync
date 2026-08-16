# claude-docs-sync

A working pattern for two problems in the Claude ecosystem:

1. **Keeping skills in sync between Claude Code (CLI) and Claude Desktop / Cowork.** There is no
   *automatic* two-way sync ([#20697](https://github.com/anthropics/claude-code/issues/20697),
   [#50644](https://github.com/anthropics/claude-code/issues/50644),
   [#52421](https://github.com/anthropics/claude-code/issues/52421),
   [#53414](https://github.com/anthropics/claude-code/issues/53414),
   [#36693](https://github.com/anthropics/claude-code/issues/36693)) — but a **git-based
   marketplace does give you one-way sync from a repo to both surfaces**, and the setup has
   several non-obvious steps that are not documented anywhere. They are written down below.
2. **Keeping the AI's project knowledge lean** — markdown docs that every session loads as
   context, without letting them rot or bloat.

It is not magic: it is git as the single source of truth, plus a documentation discipline encoded
as Claude skills so the AI itself follows and maintains it.

## The sync pattern

```
                  ┌────────────────────────────────────┐
                  │  git repo (single source of truth) │
                  │    .claude-plugin/marketplace.json │
                  │    plugins/<your-plugin>/          │
                  └───────┬────────────────────┬───────┘
            symlink, instant│                  │marketplace, on push
                            ▼                  ▼
                 ┌────────────────┐   ┌─────────────────────────┐
                 │ Claude Code CLI│   │ Claude Desktop / Cowork │
                 │ ~/.claude/     │   │ Plugins → Add →         │
                 │   skills/<p> → │   │   Add marketplace       │
                 └────────────────┘   └─────────────────────────┘
```

| Step | Automatic? |
|---|---|
| Edit → repo (with a git auto-commit tool, e.g. obsidian-git) | yes, ~10 min |
| Edit → repo (without) | no — `git add/commit/push` |
| Repo → CLI, via symlink | **yes, instant** |
| Repo → CLI, via marketplace | `claude plugin marketplace update <name>` |
| Repo → Desktop/Cowork, via marketplace | **yes, once "Sync automatically" is on** (see below) |
| Repo → Desktop/Cowork, via uploaded `.plugin` file | **no** — and there is no update path at all: you must remove the old plugin and install the new file |
| Desktop/Cowork edit → repo | no — export, copy back, commit |

### CLI side

```bash
ln -s /path/to/your-repo/plugins/your-plugin ~/.claude/skills/your-plugin
```

Claude Code reads every subdirectory of `~/.claude/skills/`, so the symlink is all it takes — every
edit is live in the next CLI session, committed or not. Note that the CLI treats the symlink target
as a plugin **only because it contains a `.claude-plugin/` directory**; without it, nothing loads.

### Desktop / Cowork side — the part nobody documents

**Plugins → Add → Add marketplace**, then enter `owner/repo`. Five things that are easy to get
wrong, each of which cost us a debugging round:

1. **Only hosted git providers work.** github.com, gitlab.com, bitbucket.org, or a GitHub
   Enterprise instance configured by your organization. A self-hosted Gitea/Forgejo URL is rejected
   with *"This host isn't supported."* — so if your source of truth is self-hosted, you need a
   mirror on one of the supported hosts (a private repo is fine; see point 3).
2. **`marketplace.json` must be at the repository root**, in `.claude-plugin/marketplace.json`.
3. **Grant the Claude GitHub App access to the repository.** The app prompts for this; it is what
   lets the marketplace read the repo — including private ones.
4. **Turn on "Sync automatically". It is OFF by default, and it is hidden.** In the plugin
   Directory, click the `...` next to the marketplace's name — the menu shows `Synced commit:
   <sha>`, a **Sync automatically** toggle, and **Check for updates**. Until you enable the
   toggle, the marketplace stays pinned at the commit it was added on, and the plugin's `Update`
   button stays greyed out forever with no explanation.
5. **Declare `version` on every plugin entry in `marketplace.json`.** Bumping `version` in the
   plugin's own `plugin.json` is *not* enough — update detection reads the marketplace manifest,
   so without a per-entry `version` there is nothing to compare and no update is ever offered.

```json
{
  "name": "your-marketplace",
  "owner": { "name": "you", "url": "https://github.com/you" },
  "metadata": { "description": "...", "version": "1.0.2" },
  "plugins": [
    {
      "name": "your-plugin",
      "source": "./plugins/your-plugin",
      "version": "1.0.2",
      "author": { "name": "you" },
      "description": "..."
    }
  ]
}
```

Validate before pushing: `claude plugin validate .claude-plugin/marketplace.json`. Be aware that
this validator does **not** check that each `SKILL.md`'s `name:` matches its directory name —
`scripts/package.sh` in this repo does.

Also: do **not** build tooling on the local session cache
(`~/Library/Application Support/Claude/local-agent-mode-sessions/.../rpm/plugin_<id>/`). The path
is session-scoped and unstable.

### If you distribute a `.plugin` file instead

`scripts/package.sh` validates the skills (frontmatter, `name` vs. directory, optional
`claude plugin validate`) and zips the plugin. Two details it encodes:

- the output **filename must not contain the version** — Cowork derives the plugin name from the
  filename, so a versioned filename creates a *new* plugin instead of updating the existing one;
- there is **no in-place update for uploaded plugins**: re-uploading fails with "already
  installed" even after a version bump. You must remove the installed plugin first. This is the
  main reason to prefer the marketplace route.

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
