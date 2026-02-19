---
allowed-tools:
  - Bash(diff:*)
  - Bash(find:*)
  - Bash(ls:*)
  - Bash(cp:*)
  - Read
  - Write
  - Edit
description: Sync dotfiles from ~/github/dotfiles to ~/stripe/configs
---

# Context

## Source Dotfiles (Mac)
Location: `~/github/dotfiles/`

Relevant files:
- `nvim/` - Neovim configuration
- `claude/` - Claude configuration (skills, commands, settings)
- `CLAUDE.md` - Claude global instructions

## Target Location

### Remote Configs Repository
Location: `~/stripe/configs/`

Should contain:
- `nvim/` (from `~/github/dotfiles/nvim/`)
- `claude/` (from `~/github/dotfiles/claude/`)
  - `skills/`
  - `commands/`
  - `CLAUDE.md`
  - `settings.json` (already customized for pay-server)

# Your Task

Execute the following steps to sync dotfiles:

## Step 1: Check nvim/ Directory Sync

Compare `~/github/dotfiles/nvim/` with `~/stripe/configs/nvim/`:

```bash
# Check if directories differ
diff -rq ~/github/dotfiles/nvim ~/stripe/configs/nvim || echo "Differences found"
```

If differences exist:
- Show what files changed using `diff -r --brief`
- Ask user if they want to sync: `cp -r ~/github/dotfiles/nvim/* ~/stripe/configs/nvim/`

## Step 2: Check claude/ Directory Sync

Compare `~/github/dotfiles/claude/` with `~/stripe/configs/claude/`:

**Important:** Preserve `~/stripe/configs/claude/settings.json` - it's customized for pay-server!

```bash
# Check skills
diff -rq ~/github/dotfiles/claude/skills ~/stripe/configs/claude/skills 2>/dev/null || echo "Skills differ"

# Check commands
diff -rq ~/github/dotfiles/claude/commands ~/stripe/configs/claude/commands 2>/dev/null || echo "Commands differ"
```

If differences exist:
- Sync skills: `cp -r ~/github/dotfiles/claude/skills/* ~/stripe/configs/claude/skills/`
- Sync commands: `cp -r ~/github/dotfiles/claude/commands/* ~/stripe/configs/claude/commands/`
- **DO NOT** overwrite `~/stripe/configs/claude/settings.json`

## Step 3: Check CLAUDE.md Sync

Compare `~/github/dotfiles/claude/CLAUDE.md` with `~/stripe/configs/claude/CLAUDE.md`:

```bash
diff ~/github/dotfiles/claude/CLAUDE.md ~/stripe/configs/claude/CLAUDE.md 2>/dev/null || echo "CLAUDE.md differs or missing"
```

If differences exist:
- Show the diff
- Ask user if they want to sync: `cp ~/github/dotfiles/claude/CLAUDE.md ~/stripe/configs/claude/CLAUDE.md`

## Step 4: Summary

Provide a summary of:
- What was synced
- What needs manual review
- Any files that were skipped (like settings.json)
- Next steps (creating PR if changes were made)

# Important Notes

- **Always preserve** `~/stripe/configs/claude/settings.json` - it has pay-server-specific configuration
- **Show diffs before making changes** so user can review
- **Ask for confirmation** before overwriting files
