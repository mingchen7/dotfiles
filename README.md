# Dotfiles

Dotfiles to quickly setup my Neovim on a new machine.
I use LazyVim for my Neovim distributions.

## Install

```sh
git clone https://github.com/mingchen7/dotfiles.git
cd ~/code/dotfiles/
mkdir -p ~/.config/nvim
rake install
```

Use homebrew to install packages.

```sh
# https://brew.sh/
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# for install fonts
brew tap homebrew/cask-fonts

# packages are managed by `Brewfile`
brew bundle install --no-lock --verbose

# install missing packages only
brew bundle install --no-upgrade --no-lock --verbose

```

## Python setup

```sh
pyenv install 3.12.2
pyenv global 3.12.2
pip install --upgrade autopep8 isort ruff pytest
```

## Tmux

Install tmux plugins manager: <https://github.com/tmux-plugins/tpm#installation>

```sh
gem install tmuxinator

cp $TMUX_RESURRECT_BACKUP ~/.tmux/resurrect/tmux_resurrect_backup.txt
ln -s ~/.tmux/resurrect/last ~/.tmux/resurrect/tmux_resurrect_backup.txt
```

## bash

```sh
# add $HOMEBREW_PREFIX/bin/bash to `/etc/shells`, then
chsh -s $HOMEBREW_PREFIX/bin/bash

# make sure that the existing ~/.bash_history doesn't have anything you wanna keep
cp $BASH_HISTORY_BACKUP ~/.bash_history
```

## zsh

```sh
powerlevel10k config

# install font
brew install font-meslo-lg-nerd-font

```

## themes

```sh
# Alacritty: https://github.com/catppuccin/alacritty
# example: install the mocha theme
curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml

# Tmux: https://github.com/catppuccin/tmux
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
```
