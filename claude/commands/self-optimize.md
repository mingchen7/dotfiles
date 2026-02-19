---
allowed-tools:
  - Bash(python3:*)
  - Bash(ls:*)
  - Bash(find:*)
  - Read
  - Edit
description: Analyze recent sessions and optimize Claude Code configuration (permissions, etc.)
---

# Context

Settings file location (symlinked):
```
!ls -la ~/.claude/settings.json
```

Current settings:
```
!cat ~/.claude/settings.json
```

Project-level settings:
```
!find ~/stripe ~/github -maxdepth 3 -path '*/.claude/settings.json' -exec echo "=== {} ===" \; -exec cat {} \; 2>/dev/null
```

# Your Task

Analyze recent Claude Code sessions and optimize the configuration. Run each optimization pass below, report findings, and propose changes for user approval.

## Pass 1: Permissions Allowlist Optimization

Scan session transcripts from the past 14 days to find tools and commands that were used but are NOT in any allow list. These are commands the user had to manually approve each time.

### Step 1: Extract all tool invocations from recent sessions

```python
python3 << 'PYEOF'
import json, os, glob, datetime
from collections import Counter

LOOKBACK_DAYS = 14
cutoff = datetime.datetime.now() - datetime.timedelta(days=LOOKBACK_DAYS)

# --- Load all current allow lists ---
allow_set = set()
# Global settings
for path in [os.path.expanduser("~/.claude/settings.json")]:
    try:
        with open(path) as f:
            allow_set.update(json.loads(f.read()).get("permissions", {}).get("allow", []))
    except Exception:
        pass

# Project-level settings
for path in glob.glob(os.path.expanduser("~/stripe/*/.claude/settings.json")) + \
            glob.glob(os.path.expanduser("~/github/*/.claude/settings.json")):
    try:
        with open(path) as f:
            allow_set.update(json.loads(f.read()).get("permissions", {}).get("allow", []))
    except Exception:
        pass

# Build set of allowed Bash prefixes (for wildcard matching)
bash_prefixes = set()
for rule in allow_set:
    if rule.startswith("Bash("):
        inner = rule[5:]
        if ":*)" in inner:
            bash_prefixes.add(inner.split(":*")[0])
        elif inner.endswith(")"):
            bash_prefixes.add(inner[:-1])

# --- Scan session transcripts ---
bash_not_allowed = Counter()  # command prefix -> count
mcp_not_allowed = Counter()   # tool name -> count

session_dirs = glob.glob(os.path.expanduser("~/.claude/projects/*/"))
for sdir in session_dirs:
    for jsonl_file in glob.glob(os.path.join(sdir, "*.jsonl")):
        if os.path.getmtime(jsonl_file) < cutoff.timestamp():
            continue
        try:
            with open(jsonl_file) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        entry = json.loads(line)
                    except Exception:
                        continue
                    msg = entry.get("message", {})
                    if not isinstance(msg, dict):
                        continue
                    content = msg.get("content", [])
                    if not isinstance(content, list):
                        continue
                    for block in content:
                        if not isinstance(block, dict) or block.get("type") != "tool_use":
                            continue
                        tool = block.get("name", "")
                        if tool == "Bash":
                            cmd = block.get("input", {}).get("command", "").strip()
                            if not cmd:
                                continue
                            base = cmd.split()[0]
                            if not any(cmd.startswith(p) for p in bash_prefixes):
                                bash_not_allowed[base] += 1
                        elif tool and tool not in allow_set:
                            # Skip built-in tools that never need permission
                            builtins = {"Read", "Edit", "Write", "Grep", "Glob",
                                        "Task", "TaskCreate", "TaskUpdate", "TaskGet",
                                        "TaskList", "TaskOutput", "TaskStop",
                                        "Skill", "AskUserQuestion", "ExitPlanMode",
                                        "EnterPlanMode", "WebFetch", "WebSearch",
                                        "NotebookEdit"}
                            if tool not in builtins:
                                mcp_not_allowed[tool] += 1
        except Exception:
            pass

# --- Report ---
print("=" * 70)
print(f"PERMISSIONS AUDIT (past {LOOKBACK_DAYS} days)")
print("=" * 70)

if bash_not_allowed:
    print("\n## Bash commands NOT in allow list (prompted each time):\n")
    for cmd, count in sorted(bash_not_allowed.items(), key=lambda x: -x[1]):
        if count >= 2:
            print(f"  [{count:3d}x]  Bash({cmd}:*)")
else:
    print("\nNo unapproved Bash commands found.")

if mcp_not_allowed:
    print("\n## MCP tools NOT in allow list (prompted each time):\n")
    for tool, count in sorted(mcp_not_allowed.items(), key=lambda x: -x[1]):
        if count >= 2:
            print(f"  [{count:3d}x]  {tool}")
else:
    print("\nNo unapproved MCP tools found.")

if not bash_not_allowed and not mcp_not_allowed:
    print("\n✓ All frequently-used tools are already in the allow list.")
PYEOF
```

### Step 2: Classify and propose changes

Review the output from Step 1. Classify each unapproved command/tool into:

1. **Safe to auto-allow** — read-only operations, standard dev tools, linting, testing, git read ops.
   Add these to `~/.claude/settings.json` → `permissions.allow`.

2. **Keep prompting** — destructive commands (`rm`, `git reset --hard`, `git clean`, `git push --force`).
   Do NOT add these. Explicitly mention them as intentionally excluded.

3. **Project-specific** — tools only relevant to one project (e.g., pay-server JS tooling).
   Propose adding these to the project-level `.claude/settings.json` instead.

### Step 3: Apply changes

After presenting the proposed changes and getting user confirmation:
- Edit `~/github/dotfiles/claude/settings.json` (the global settings source of truth)
- For project-specific rules, edit the appropriate project `.claude/settings.json`
- Show a diff summary of what was added

## Pass 2: Unused Permissions Cleanup (optional)

Check if any rules in the allow list were never used in the past 14 days.
Report them but do NOT remove automatically — just flag for the user's awareness.

```python
python3 << 'PYEOF'
import json, os, glob, datetime
from collections import defaultdict

LOOKBACK_DAYS = 14
cutoff = datetime.datetime.now() - datetime.timedelta(days=LOOKBACK_DAYS)

# Load global allow list
with open(os.path.expanduser("~/.claude/settings.json")) as f:
    settings = json.loads(f.read())
allow_list = settings.get("permissions", {}).get("allow", [])

# Track which rules matched at least once
rule_used = defaultdict(int)

# Build prefix map for Bash rules
bash_rules = {}
non_bash_rules = set()
for rule in allow_list:
    if rule.startswith("Bash("):
        inner = rule[5:]
        if ":*)" in inner:
            prefix = inner.split(":*")[0]
        elif inner.endswith(")"):
            prefix = inner[:-1]
        else:
            prefix = inner
        bash_rules[prefix] = rule
    else:
        non_bash_rules.add(rule)

# Scan sessions
session_dirs = glob.glob(os.path.expanduser("~/.claude/projects/*/"))
for sdir in session_dirs:
    for jsonl_file in glob.glob(os.path.join(sdir, "*.jsonl")):
        if os.path.getmtime(jsonl_file) < cutoff.timestamp():
            continue
        try:
            with open(jsonl_file) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        entry = json.loads(line)
                    except Exception:
                        continue
                    msg = entry.get("message", {})
                    if not isinstance(msg, dict):
                        continue
                    content = msg.get("content", [])
                    if not isinstance(content, list):
                        continue
                    for block in content:
                        if not isinstance(block, dict) or block.get("type") != "tool_use":
                            continue
                        tool = block.get("name", "")
                        if tool == "Bash":
                            cmd = block.get("input", {}).get("command", "").strip()
                            for prefix, rule in bash_rules.items():
                                if cmd.startswith(prefix):
                                    rule_used[rule] += 1
                        elif tool in non_bash_rules:
                            rule_used[tool] += 1
        except Exception:
            pass

print("=" * 70)
print(f"UNUSED PERMISSIONS (no hits in past {LOOKBACK_DAYS} days)")
print("=" * 70)
unused = [r for r in allow_list if rule_used.get(r, 0) == 0]
if unused:
    for r in unused:
        print(f"  {r}")
    print(f"\n({len(unused)} unused rules out of {len(allow_list)} total)")
    print("These may still be needed for infrequent workflows — review before removing.")
else:
    print("\nAll rules were used at least once. No cleanup needed.")
PYEOF
```

Report unused rules but let the user decide whether to remove any.

## Output Format

After all passes, provide a summary:

```
## Self-Optimize Summary

### Permissions Added
- <list of new rules added to global settings>
- <list of new rules added to project settings>

### Permissions Kept as Manual
- <list of commands intentionally left requiring approval>

### Unused Permissions (for review)
- <list of rules with 0 usage in lookback period>

### Next Steps
- <any recommendations>
```

# Important Notes

- **Never auto-allow destructive commands**: `rm`, `git reset --hard`, `git clean -f`, `git push --force`, `git branch -D`
- **Always show proposed changes before applying** — get explicit user confirmation
- **Global vs project settings**: Put broadly-useful rules in global settings, project-specific rules in project settings
- The global settings source of truth is `~/github/dotfiles/claude/settings.json` (symlinked to `~/.claude/settings.json`)
- After editing, remind user to run `/sync-remote-dotfiles` to push changes to devbox
