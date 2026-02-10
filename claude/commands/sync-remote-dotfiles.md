---
allowed-tools:
  - Bash(diff:*)
  - Bash(find:*)
  - Bash(ls:*)
  - Bash(cp:*)
  - Read
  - Write
  - Edit
description: Sync dotfiles from ~/github/dotfiles to ~/stripe/configs and ~/stripe/pay-server/devbox/dotfiles/mingc/
---

# Context

## Source Dotfiles (Mac)
Location: `~/github/dotfiles/`

Relevant files:
- `nvim/` - Neovim configuration
- `claude/` - Claude configuration (skills, commands, settings)
- `bashrc` - Bash configuration
- `sharedrc` - Shared shell configuration
- `zshrc` - Zsh configuration

## Target Locations

### 1. Remote Configs Repository
Location: `~/stripe/configs/`

Should contain:
- `nvim/` (from `~/github/dotfiles/nvim/`)
- `claude/` (from `~/github/dotfiles/claude/`)
  - `skills/`
  - `commands/`
  - `settings.json` (already customized for pay-server)

### 2. Pay-Server Dotfiles
Location: `~/stripe/pay-server/devbox/dotfiles/mingc/`

Should contain:
- `.bashrc` (from `bashrc`, Linux-compatible)
- `.zshrc` (from `zshrc`, Linux-compatible with oh-my-zsh)
- `.sharedrc` (from `sharedrc`, Linux-compatible)
- `.vimrc` (from `vimrc`)
- `.tmux.conf` (from `tmux.conf`)
- `.p10k.zsh` (from `~/.p10k.zsh`)
- `setup.sh` (custom installation script)
- `metadata.yaml`
- `software.json`

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

## Step 3: Check Key Dotfiles (bashrc, zshrc, sharedrc)

For each file, compare source with target:

```bash
# Check .bashrc
diff ~/github/dotfiles/bashrc ~/stripe/pay-server/devbox/dotfiles/mingc/.bashrc

# Check .zshrc
diff ~/github/dotfiles/zshrc ~/stripe/pay-server/devbox/dotfiles/mingc/.zshrc

# Check .sharedrc
diff ~/github/dotfiles/sharedrc ~/stripe/pay-server/devbox/dotfiles/mingc/.sharedrc
```

### Mac to Linux Conversion Rules

When syncing these files, apply these transformations:

**Remove Homebrew sections:**
- Remove entire `### BEGIN HOMEBREW` to `### END HOMEBREW` blocks
- Change `$HOMEBREW_PREFIX/opt/fzf/shell/...` → `~/.fzf.bash` or `~/.fzf.zsh`
- Change `source /opt/homebrew/share/...` → use oh-my-zsh plugin system or remove

**Keep Stripe-specific sections:**
- Preserve `### BEGIN STRIPE` to `### END STRIPE` blocks
- Preserve all Stripe shell init sources

**For .zshrc specifically:**
- Ensure oh-my-zsh setup is present:
  ```bash
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="powerlevel10k/powerlevel10k"
  plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
  source $ZSH/oh-my-zsh.sh
  ```
- Ensure Stripe-specific lines are present:
  ```bash
  # ===== Stripe =====
  autoload -Uz compinit; compinit
  autoload -Uz bashcompinit; bashcompinit
  source ~/.bashrc
  eval "$(nodenv init -)"
  compdef _git stripe-git=git
  typeset -aU path
  ```

**For .bashrc specifically:**
- Add `export SHELL=/bin/zsh` near the top
- Ensure fzf sources from `~/.fzf.bash`

**For .sharedrc:**
- Remove bat/btm/autojump sections that use `$HOMEBREW_PREFIX`
- Keep all other aliases and functions

If changes needed:
1. Show the differences
2. Explain what conversions are needed
3. Ask user to confirm before updating files

## Step 4: Check Other Dotfiles

Compare and sync if needed:

```bash
diff ~/github/dotfiles/vimrc ~/stripe/pay-server/devbox/dotfiles/mingc/.vimrc
diff ~/github/dotfiles/tmux.conf ~/stripe/pay-server/devbox/dotfiles/mingc/.tmux.conf
diff ~/.p10k.zsh ~/stripe/pay-server/devbox/dotfiles/mingc/.p10k.zsh
```

## Step 5: Review setup.sh

Read `~/stripe/pay-server/devbox/dotfiles/mingc/setup.sh` and verify:

1. **Installation functions are correct:**
   - `install_oh_my_zsh()` - installs oh-my-zsh from GitHub
   - `install_powerlevel10k()` - installs theme
   - `install_fzf()` - installs fzf from GitHub
   - `install_zsh_autosuggestions()` - installs plugin
   - `install_zsh_syntax_highlighting()` - installs plugin

2. **Copy functions point to correct paths:**
   - `setup_nvim()` copies from `~/stripe/configs/nvim/` to `~/.config/nvim/`
   - `setup_claude()` copies from `~/stripe/configs/claude/` to `~/.config/claude/`

3. **Main execution calls all functions**

If any paths are incorrect, suggest updates.

## Step 6: Summary

Provide a summary of:
- What was synced
- What needs manual review
- Any files that were skipped (like settings.json)
- Next steps (creating PR if changes were made)

# Important Notes

- **Always preserve** `~/stripe/configs/claude/settings.json` - it has pay-server-specific configuration
- **Apply Mac → Linux conversions** when syncing bashrc/zshrc/sharedrc
- **Show diffs before making changes** so user can review
- **Ask for confirmation** before overwriting files
- The source dotfiles (`~/github/dotfiles/`) are Mac-specific
- The target dotfiles must work in Linux remote boxes (no Homebrew)
