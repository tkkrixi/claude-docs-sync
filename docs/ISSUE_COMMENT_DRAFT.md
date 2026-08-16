# Draft comment for the GitHub issues (post manually if you agree)

Target issues: anthropics/claude-code #20697, #50644, #52421, #53414, #36693.
Adjust the first line per issue so it doesn't read as spam; post to 1–2 of the most
relevant ones (#20697 and #50644), not all five.

---

Until this lands natively, here is a workaround pattern I've been running daily across
Claude Code CLI and Claude Desktop/Cowork on the same skills:

- **Single source of truth:** the plugin (skills) lives in a git repo together with my
  markdown knowledge base.
- **CLI side is fully automatic:** `~/.claude/skills/<plugin>` is a symlink into the repo
  working copy — every edit is live in the next CLI session, nothing to sync.
- **Desktop/Cowork side is one manual step per version:** a packaging script validates the
  skills and zips a `.plugin` file for upload. Two gotchas that cost me time: the filename
  must not contain the version (Cowork derives the plugin name from the filename, so a
  versioned name creates a duplicate plugin), and the local session cache under
  `local-agent-mode-sessions/` is session-scoped — don't build on it.
- A git auto-commit tool (obsidian-git in my case) makes the repo side hands-free.

Repo with the scripts, the skills (sanitized) and a longer write-up:
https://github.com/tkkrixi/claude-docs-sync

Native support would still be much better — the manual desktop upload is the remaining
friction this can't remove.
