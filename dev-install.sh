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

echo "Installing tools using mise..."
mise install

echo "Installing neovim configuration..."
git clone https://github.com/nollidnosnhoj/kickstart.nvim $HOME/.config/nvim
echo "Run 'nvim' to install neovim plugins."

echo "Switching to zsh..."
chsh -s /bin/zsh

echo "Development installation completed!"