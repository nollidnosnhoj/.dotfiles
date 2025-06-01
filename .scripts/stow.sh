#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CURRENT_DIR=$(pwd)
STOW_PATHS=$1

if ! command -v stow $> /dev/null; then
    echo "Installing stow..."
    sudo pacman -S --needed --noconfirm stow
fi

local log_file=$CURRENT_DIR/stow_arch_output.log

echo "Symlinking dotfiles from $CURRENT_DIR to $HOME..."

for folder in $(echo $STOW_PATHS | sed "s/,/ /g"); do
    echo "stow $folder"
    stow -D $folder
    rm -rf $XDG_CONFIG_HOME/$folder
    stow $folder 
    
    # Check exit status
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        echo "Stow failed to symlink files."
        exit
    fi
done

echo "Stow operation successful!"