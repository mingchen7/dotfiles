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

# autoenv
source $(brew --prefix autoenv)/activate.sh
AUTOENV_ENABLE_LEAVE=yes
AUTOENV_VIEWER=cat
