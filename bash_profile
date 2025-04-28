# vim: set ft=sh :

# ### BEGIN STRIPE
# All Stripe related shell configuration
# is at ~/.stripe/shellinit/bash_profile and is
# persistently managed by Chef. You shouldn't
# remove this unless you don't want to load
# Stripe specific shell configurations.
#
# Feel free to add your customizations in this
# file (~/.bash_profile) after the Stripe config
# is sourced.
if [[ -f ~/.stripe/shellinit/bash_profile ]]; then
	source ~/.stripe/shellinit/bash_profile
fi
### END STRIPE

# START - Managed by chef cookbook stripe_cpe_bin
alias tc='/usr/local/stripe/bin/test_cookbook'
alias cz='/usr/local/stripe/bin/chef-zero'
alias cookit='tc && cz'
# STOP - Managed by chef cookbook stripe_cpe_bin

[[ -s $HOME/.bashrc ]] && source $HOME/.bashrc
[[ -s "$HOME/.bash_profile.local" ]] && source "$HOME/.bash_profile.local"

eval "$(nodenv init - bash)"
