# vim: set ft=sh :

[[ -s $HOME/.bashrc ]] && source $HOME/.bashrc
[[ -s "$HOME/.bash_profile.local" ]] && source "$HOME/.bash_profile.local"

eval "$(nodenv init - bash)"
