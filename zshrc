### BEGIN HOMEBREW FOR APPLE SILICON
if [[ $(/usr/bin/uname -m) == "arm64" ]]; then
  if [[ -f /opt/homebrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew";
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
    export HOMEBREW_REPOSITORY="/opt/homebrew";
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
    export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
  fi
fi
### END HOMEBREW

### BEGIN STRIPE
# All Stripe related shell configuration
# is at ~/.stripe/shellinit/zshrc and is
# persistently managed by Chef. You shouldn't
# remove this unless you don't want to load
# Stripe specific shell configurations.
#
# Feel free to add your customizations in this
# file (~/.zshrc) after the Stripe config
# is sourced.
if [[ -f ~/.stripe/shellinit/zshrc ]]; then
  source ~/.stripe/shellinit/zshrc
fi
### END STRIPE

# History setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ls="eza --icons=always"

# Source the common configuration file if it exists
if [ -f "$HOME/.sharedrc" ]; then
  source "$HOME/.sharedrc"
fi

[[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]] && source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
[[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]] && source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"

alias tmux="TERM=screen-256color-bce tmux"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

alias lg='lazygit'
alias gst='git status'

# herdr: register running devboxes as herdr machines
[[ -x "$HOME/stripe/configs/bin/herdr-sync-machines" ]] && alias herdr-sync-machines="$HOME/stripe/configs/bin/herdr-sync-machines"

# Wait for a new box to be running and to have herdr (installed by dotfiles
# setup.sh), then add it to the herdr sidebar. Waiting for herdr avoids
# `machine add`'s own installer, which mydata's egress proxy blocks.
_herdr_register_new_box() {
  local name="$1"
  local deadline=$((SECONDS + 900))
  export DEVBOX_SSH_NO_UPDATE_ACCESS=1
  until pay remote list -a --raw \
    | jq -e --arg n "$name" 'any(.[]; .name == $n and (.status | ascii_downcase) == "running")' >/dev/null; do
    if (( SECONDS > deadline )); then
      echo "timed out waiting for $name to run; register it later with herdr-sync-machines" >&2
      return 0
    fi
    sleep 5
  done
  until ssh -n -o BatchMode=yes -o ConnectTimeout=25 "$name" 'command -v herdr' >/dev/null 2>&1; do
    if (( SECONDS > deadline )); then
      echo "herdr not on $name yet (dotfiles still running?); register it later with herdr-sync-machines" >&2
      return 0
    fi
    sleep 15
  done
  local emoji
  emoji="$(pay remote list --raw | jq -r --arg n "$name" '.[] | select(.name == $n) | .emoji // empty')"
  herdr machine add "$name" --label "${emoji:+$emoji }$name"
}

# Create a remote devbox and add it to herdr. Branch is mingc/<name>.
# Usage: newbox <name> [mint-workspace, default pay-server]
newbox() {
  local name="$1" workspace="${2:-pay-server}"
  if [[ -z "$name" ]]; then
    echo "Usage: newbox <name> [workspace]"
    return 1
  fi
  # No --ssh: it blocks until that session exits, so registration would wait too.
  pay remote new "$name" --repo mint --workspace "$workspace" \
    --ide none --no-notify-on-ready --skip-confirm || return 1
  _herdr_register_new_box "$name"
}

# Create a remote mydata and add it to herdr. Branch is mingc/<name>.
# Usage: newdata <name> [mint-workspace, default zoolander] [size: small|medium|large, default medium]
newdata() {
  local name="$1" workspace="${2:-zoolander}" size="${3:-medium}"
  if [[ -z "$name" ]]; then
    echo "Usage: newdata <name> [workspace] [small|medium|large]"
    return 1
  fi
  pay remote new "$name" --host-type "mydata-$size" --repo mint --workspace "$workspace" \
    --ide none --no-notify-on-ready --skip-confirm || return 1
  _herdr_register_new_box "$name"
}

# autoenv
# source $(brew --prefix autoenv)/activate.sh
# AUTOENV_ENABLE_LEAVE=yes
# AUTOENV_VIEWER=cat
