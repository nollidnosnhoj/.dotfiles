#!/usr/bin/env bash

DOTFILES_DIR=$HOME/.dotfiles
SCRIPTS_DIR=$DOTFILES_DIR/.scripts
STOW_PATHS="mise,oh-my-posh,zsh"
DEV_PACKAGES=(
    zsh
    oh-my-posh
    mise
    neovim-git
    zoxide
    eza
    fzf
    github-cli
    lazygit
)

source $SCRIPTS_DIR/utils.sh

source $SCRIPTS_DIR/git_setup.sh
source $SCRIPTS_DIR/yay.sh

echo "Installing development packages..."
yay -S --needed --noconfirm "${DEV_PACKAGES[@]}"

echo "Stowing dotfiles..."
source $SCRIPTS_DIR/stow.sh $STOW_PATHS

echo "Installing tools using mise..."
mise install

if [ ! -d $HOME/.config/nvim ]; then
    echo "Installing neovim configuration..."
    git clone https://github.com/nollidnosnhoj/kickstart.nvim $HOME/.config/nvim
    echo "Run 'nvim' to install neovim plugins."
fi

if [[ "$SHELL" == *"/zsh" ]]; then
  echo "The login shell is already /bin/zsh"
else
    echo "Switching to zsh..."
    chsh -s /bin/zsh
fi

echo "Development installation completed!"