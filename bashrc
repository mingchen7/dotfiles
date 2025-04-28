### BEGIN STRIPE
# All Stripe related shell configuration
# is at ~/.stripe/shellinit/bashrc and is
# persistently managed by Chef. You shouldn't
# remove this unless you don't want to load
# Stripe specific shell configurations.
#
# Feel free to add your customizations in this
# file (~/.bashrc) after the Stripe config
# is sourced.
[ -f ~/.stripe/shellinit/bashrc ] && source ~/.stripe/shellinit/bashrc
### END STRIPE

### BEGIN HOMEBREW FOR APPLE SILICON
if [[ $(/usr/bin/uname -m) == "arm64" ]]; then
	if [[ -f /opt/homebrew/bin/brew ]]; then
		export HOMEBREW_PREFIX="/opt/homebrew"
		export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
		export HOMEBREW_REPOSITORY="/opt/homebrew"
		export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/llvm/bin:/opt/homebrew/opt/python/bin${PATH+:$PATH}"
		if [[ ":$LIBRARY_PATH:" != *":/opt/homebrew/lib:"* ]]; then
			export LIBRARY_PATH="$LIBRARY_PATH:/opt/homebrew/lib"
		fi
		export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
		export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
		# export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH
	fi
else
	if [[ -f /usr/local/bin/brew ]]; then
		export HOMEBREW_PREFIX="/usr/local"
		export HOMEBREW_CELLAR="/usr/local/Cellar"
		export HOMEBREW_REPOSITORY="/opt/homebrew"
		export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/opt/llvm/bin:/usr/local/opt/python/bin:$PATH"
		if [[ ":$LIBRARY_PATH:" != *":/usr/local/lib:"* ]]; then
			export LIBRARY_PATH="$LIBRARY_PATH:/usr/local/lib"
		fi
		export MANPATH="/usr/local/share/man${MANPATH+:$MANPATH}:"
		export INFOPATH="/usr/local/share/info:${INFOPATH:-}"
	fi
fi
### END HOMEBREW FOR APPLE SILICON

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
