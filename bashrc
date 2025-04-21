[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

# Source the common configuration file if it exists
if [ -f "$HOME/.sharedrc" ]; then
  source "$HOME/.sharedrc"
fi

# ------ Below are Bash specific settings -----
## Enable history expansion with space ## E.g. typing !!<space> will replace the !! with your last command
bind Space:magic-space

## Turn on recursive globbing (enables ** to recurse all directories)
shopt -s globstar 2>/dev/null

## SMARTER TAB-COMPLETION (Readline bindings) ##

## Perform file completion in a case insensitive fashion
bind "set completion-ignore-case on"

## Treat hyphens and underscores as equivalent
bind "set completion-map-case on"

## Display matches for ambiguous patterns at first tab press
bind "set show-all-if-ambiguous on"

## on menu-complete, first display the common prefix, then cycle through the
# options when hitting TAB
bind "set menu-complete-display-prefix on"

## Save multi-line commands as one command
shopt -s cmdhist

## Enable incremental history search with up/down arrows (also Readline goodness)
## Learn more about this here: http://codeinthehole.com/writing/the-most-important-command-line-tip-incremental-history-searching-with-inputrc/
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[C": forward-char'
bind '"\e[D": backward-char'

## Prepend cd to directory names automatically
shopt -s autocd 2>/dev/null
## Correct spelling errors during tab-completion
shopt -s dirspell 2>/dev/null
## Correct spelling errors in arguments supplied to cd
shopt -s cdspell 2>/dev/null

shopt -s histappend
export HISTSIZE=-1
export HISTFILESIZE=-1
export HISTCONTROL=ignoredups:erasedups

if ! echo "$PROMPT_COMMAND" | grep -q history; then
  export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
fi

# fzf
[[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.bash" ]] && source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.bash"
[[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.bash" ]] && source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.bash"

## git completion
# git_completion="$HOMEBREW_PREFIX/etc/bash_completion.d/git-completion.bash"
# if [ -r "$git_completion" ]; then
#   source "$git_completion"
# fi
# unset git_completion
#

alias tmux="TERM=screen-256color-bce tmux"
