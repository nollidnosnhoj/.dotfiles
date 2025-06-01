#!/usr/bin/env bash

if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd .. && rm -rf yay
    export PATH="$PATH:$HOME/.local/bin"
else
    echo "yay is already installed."
fi