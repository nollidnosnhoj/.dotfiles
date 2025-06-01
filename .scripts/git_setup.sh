#!/usr/bin/env bash

if ! command -v git &> /dev/null; then
    echo "Git was not installed... Installing git..."
    sudo pacman -S --needed --noconfirm git base-devel
fi

echo "Copying Git configuration..."
if [ ! -f $HOME/.gitconfig ]; then
    rm $HOME/.gitconfig
fi
cp ./git/.gitconfig $HOME/.gitconfig