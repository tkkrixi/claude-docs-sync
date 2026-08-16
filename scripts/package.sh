#!/usr/bin/env bash
# Packages a Claude plugin into a .plugin file for Cowork/desktop upload.
# Format: the plugin root (.claude-plugin/plugin.json with skills/ next to it) is the zip
# root, NOT nested under an extra folder level — this matches the official packaging recipe
# of Cowork's built-in "create-cowork-plugin" skill, Phase 5
# (`zip -r plugin-name.plugin .` run inside the plugin directory).
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") [-f] [plugin-dir]" >&2
  echo "  -f           package even if the repo has uncommitted changes (no confirmation)" >&2
  echo "  plugin-dir   plugin root to package (default: ../plugins/docs-workflow next to this script)" >&2
  exit 1
}

FORCE=0
while getopts ":f" opt; do
  case "$opt" in
    f) FORCE=1 ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="${1:-$SCRIPT_DIR/../plugins/docs-workflow}"
OUT_DIR="$SCRIPT_DIR/dist"

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "ERROR: plugin directory not found: $PLUGIN_DIR" >&2
  exit 1
fi
PLUGIN_DIR="$(cd "$PLUGIN_DIR" && pwd)"
MANIFEST="$PLUGIN_DIR/.claude-plugin/plugin.json"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: plugin manifest not found: $MANIFEST" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: this script requires jq (brew install jq)." >&2
  exit 1
fi
if ! command -v zip >/dev/null 2>&1; then
  echo "ERROR: this script requires zip." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: this script requires python3 for the SKILL.md frontmatter check." >&2
  exit 1
fi

if ! PLUGIN_NAME="$(jq -er '.name' "$MANIFEST" 2>/dev/null)"; then
  echo "ERROR: plugin.json is invalid JSON or has no 'name' field: $MANIFEST" >&2
  exit 1
fi
if ! VERSION="$(jq -er '.version' "$MANIFEST" 2>/dev/null)"; then
  echo "ERROR: plugin.json has no 'version' field: $MANIFEST" >&2
  exit 1
fi

echo "Plugin: $PLUGIN_NAME   version: $VERSION"
echo

# --- 1. git cleanliness check (scoped to the plugin directory) ---
DIRTY=""
COMMIT_HASH="unknown"
if git -C "$PLUGIN_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  DIRTY="$(git -C "$PLUGIN_DIR" status --porcelain -- .)"
  if [[ -n "$DIRTY" ]]; then
    echo "WARNING: uncommitted changes in the plugin directory:" >&2
    echo "$DIRTY" | sed 's/^/  /' >&2
    echo >&2
    if [[ "$FORCE" -eq 1 ]]; then
      echo "Continuing because of -f — the package will contain uncommitted state." >&2
    else
      read -r -p "Package from an uncommitted state anyway? [y/N] " ANSWER
      if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
        echo "Aborted. Commit your changes, or run with -f." >&2
        exit 1
      fi
    fi
  fi
  COMMIT_HASH="$(git -C "$PLUGIN_DIR" rev-parse --short HEAD)"
else
  echo "WARNING: the plugin directory is not in a git repo — commit hash stays unknown." >&2
fi

# --- 2. skill checks: SKILL.md exists, YAML frontmatter valid, name/description present, name == dir name ---
echo
echo "Checking skills..."
SKILLS_DIR="$PLUGIN_DIR/skills"
if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "ERROR: no skills/ directory in the plugin: $SKILLS_DIR" >&2
  exit 1
fi

SKILL_LIST=()
for skill_path in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_path" ]] || continue
  skill_dir_name="$(basename "$skill_path")"
  skill_md="${skill_path}SKILL.md"
  if [[ ! -f "$skill_md" ]]; then
    echo "ERROR: missing SKILL.md: $skill_md" >&2
    exit 1
  fi

  RESULT="$(python3 - "$skill_md" "$skill_dir_name" <<'PYEOF'
import sys, re
try:
    import yaml
except ImportError:
    print("NOYAML")
    sys.exit(0)
path, dirname = sys.argv[1], sys.argv[2]
content = open(path, encoding="utf-8").read()
m = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
if not m:
    print("NOFRONTMATTER")
    sys.exit(0)
try:
    data = yaml.safe_load(m.group(1))
except Exception as e:
    print(("YAMLERROR:" + str(e)).splitlines()[0])
    sys.exit(0)
if not isinstance(data, dict):
    print("NOTMAPPING")
    sys.exit(0)
name = data.get("name")
desc = data.get("description")
if not name:
    print("NONAME")
    sys.exit(0)
if not desc:
    print("NODESC")
    sys.exit(0)
if name != dirname:
    print("NAMEMISMATCH:" + str(name))
    sys.exit(0)
print("OK")
PYEOF
)"

  case "$RESULT" in
    OK)
      SKILL_LIST+=("$skill_dir_name")
      ;;
    NOYAML)
      echo "ERROR: python3 has no 'yaml' module (pip install pyyaml); cannot check: $skill_md" >&2
      exit 1
      ;;
    NOFRONTMATTER)
      echo "ERROR: no YAML frontmatter ('---' delimiters) in: $skill_md" >&2
      exit 1
      ;;
    NOTMAPPING)
      echo "ERROR: the frontmatter is not a YAML mapping: $skill_md" >&2
      exit 1
      ;;
    NONAME)
      echo "ERROR: missing 'name:' field in the frontmatter: $skill_md" >&2
      exit 1
      ;;
    NODESC)
      echo "ERROR: missing 'description:' field in the frontmatter: $skill_md" >&2
      exit 1
      ;;
    NAMEMISMATCH:*)
      found="${RESULT#NAMEMISMATCH:}"
      echo "ERROR: the frontmatter name ('$found') does not match the directory name ('$skill_dir_name'): $skill_md" >&2
      exit 1
      ;;
    YAMLERROR:*)
      err="${RESULT#YAMLERROR:}"
      echo "ERROR: the YAML frontmatter cannot be parsed ($err): $skill_md" >&2
      exit 1
      ;;
    *)
      echo "ERROR: unknown check result ('$RESULT'): $skill_md" >&2
      exit 1
      ;;
  esac
done

if [[ ${#SKILL_LIST[@]} -eq 0 ]]; then
  echo "ERROR: no skills found under $SKILLS_DIR." >&2
  exit 1
fi
echo "  ${#SKILL_LIST[@]} skill(s) OK: ${SKILL_LIST[*]}"

# --- 3. official 'claude plugin validate' if available (supplements step 2, does not replace it) ---
CLAUDE_BIN="$(command -v claude || true)"
if [[ -z "$CLAUDE_BIN" && -x "$HOME/.local/bin/claude" ]]; then
  CLAUDE_BIN="$HOME/.local/bin/claude"
fi
if [[ -n "$CLAUDE_BIN" ]]; then
  echo
  echo "Official validation ('claude plugin validate')..."
  if ! "$CLAUDE_BIN" plugin validate "$MANIFEST"; then
    echo "ERROR: 'claude plugin validate' reported a problem, see above." >&2
    exit 1
  fi
else
  echo "WARNING: no 'claude' CLI on the PATH; skipping the official validation (step 2's own checks did run)." >&2
fi

# --- 4. packaging: plugin root = zip root, NOT nested under an extra folder level ---
mkdir -p "$OUT_DIR"
if [[ ! -f "$OUT_DIR/.gitignore" ]]; then
  printf '*\n!.gitignore\n' > "$OUT_DIR/.gitignore"
fi

OUT_FILE="$OUT_DIR/${PLUGIN_NAME}.plugin"
ARCHIVE_DIR="$OUT_DIR/archive"
ARCHIVE_FILE="$ARCHIVE_DIR/${PLUGIN_NAME}-${VERSION}.plugin"

if [[ -f "$OUT_FILE" ]]; then
  echo
  echo "WARNING: overwriting the existing package: $OUT_FILE" >&2
fi

TMP_ZIP="$(mktemp -t "${PLUGIN_NAME}").plugin"
rm -f "$TMP_ZIP"
( cd "$PLUGIN_DIR" && zip -rq "$TMP_ZIP" . -x "*.DS_Store" )
mv "$TMP_ZIP" "$OUT_FILE"

mkdir -p "$ARCHIVE_DIR"
cp "$OUT_FILE" "$ARCHIVE_FILE"

SIZE_HUMAN="$(du -h "$OUT_FILE" | cut -f1 | tr -d ' ')"

echo
echo "=== Done ==="
echo "Package (install this one): $OUT_FILE"
echo "Version: $VERSION"
echo "Size:    $SIZE_HUMAN"
echo "Versioned archive copy: $ARCHIVE_FILE"
echo "Skills (${#SKILL_LIST[@]}): ${SKILL_LIST[*]}"
echo "Git commit: $COMMIT_HASH"
if [[ -n "$DIRTY" ]]; then
  echo "WARNING: the package contains uncommitted changes — the commit hash above is NOT the full packaged state!"
fi
echo
echo "NOTE: the output filename deliberately contains no version — Cowork derives the plugin name from the filename, so a versioned filename would create a NEW plugin instead of updating the existing one."
