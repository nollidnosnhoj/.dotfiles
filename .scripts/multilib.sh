#!/usr/bin/env bash

if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    sudo tee -a /etc/pacman.conf > /dev/null <<EOT

[multilib]
Include = /etc/pacman.d/mirrorlist
EOT
    echo "Multilib repository has been enabled."
else
    echo "Multilib repository is already enabled."
fi