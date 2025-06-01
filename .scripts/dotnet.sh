#!/usr/bin/env bash

echo "Installing latest dotnet versions..."
yay -S --needed --noconfirm dotnet-host-bin dotnet-sdk-bin dotnet-runtime-bin

echo "Installing Jetbrains Toolbox..."
echo "[NOTE] Installing Rider through Jetbrains Toolbox means you will have to update Rider through Jetbrains Toolbox, not AUR"
sudo pacman -S jetbrains-toolbox