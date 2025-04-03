#!/bin/bash

# Function to ask yes or no questions
ask_yes_no() {
    while true; do
        read -p "$1 (Yy/Nn): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer with y or n.";;
        esac
    done
}

# Function to check and enable multilib repository
enable_multilib() {
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
}

install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Installing yay..."
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si
        cd .. && rm -rf yay
        export PATH="$PATH:$HOME/.local/bin"
    else
        echo "yay is already installed."
    fi
}

enable_chaotic_aur() {
    if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        echo "Chaotic AUR is already enabled."
    else
        echo "Enabling Chaotic AUR..."
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy
    fi
}

# Function to install AMD GPU drivers and tools
install_amd() {
    echo "Installing AMD GPU drivers and tools..."
    sudo pacman -S --needed mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader
    yay -S lact
}

# Symlink dotfiles using GNU Stow
symlink_dotfiles() {
  local source_dir="$1"
  local target_dir="${2:-$HOME}"
  local log_file="${3:-stow_output.log}"

  echo "Symlinking dotfiles from $source_dir to $target_dir..."

  if [ ! -d $source_dir ]; then
      mkdir -p $source_dir
  fi

  # Run stow and capture output
  stow -v -t "$target_dir" . 2>&1 | tee "$log_file"

  # Check exit status
  if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
      echo "Stow failed to symlink files. Check $logfile for details"
      exit
  fi

  echo "Dotfiles symlinked successfully"
}

install_sddm() {
    echo "installing sddm and theme dependencies..."
    sudo pacman -S --needed sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
    echo "setting up sddm theme..."
    sudo git clone -b master --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
    sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/

    sudo cp ./sddm/sddm.conf /etc/sddm.conf
    sudo cp ./sddm/theme.conf /usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut-nord.conf
    sudo cp ./wallpapers/default-wallpaper.png /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/nord-d2-beyond-light.png
    sudo sed -i 's/^ConfigFile=.*$/ConfigFile=Themes\/astronaut-nord.conf/' /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop

    echo "[Theme]
    Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
    if [ ! -d /etc/sddm.conf.d/ ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi
    sudo touch /etc/sddm.conf.d/virtualkbd.conf
    echo "[General]
    InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf
    echo "Enabling sddm service backend..."
    sudo systemctl enable --now sddm.service
}

PACKAGES=(
    git ufw bluez bluez-utils pavucontrol gst-plugin-pipewire pipewire pipewire-alsa
    pipewire-audio pipewire-jack pipewire-pulse wireplumber networkmanager
    network-manager-applet blueman brightnessctl nerd-fonts noto-fonts
    noto-fonts-emoji thunar swaync grim hyprland kitty polkit-kde-agent qt5-wayland
    qt6-wayland slurp wofi rofi-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    nwg-look nwg-displays waybar swww imagemagick hypridle hyprlock hyprshade
    oh-my-posh qt5ct qt6ct zsh zen-browser code zed neovim lazygit eza zoxide fzf unzip
    man-db man-pages udiskie
)

AUR_PACKAGES=(
    wlogout papirus-icon-theme-git bibata-cursor-theme-bin gowall swayosd-git
    clipse grimblast-git waypaper flameshot-git
)

echo "Installing my dotfiles..."

echo "Enhancing git..."
git config --global http.postBuffer 157286400

echo "Configuring pacman..."
sudo sed -i 's/^#Color/Color/; s/^#VerbosePkgLists/VerbosePkgLists/; s/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
enable_multilib

install_yay
enable_chaotic_aur

echo "Reducing package compression time..."
sudo sed -i 's/COMPRESSZST=(zstd -c -T0 --ultra -20 -)/COMPRESSZST=(zstd -c -T0 --fast -)/' /etc/makepkg.conf

echo "Installing required packages using pacman..."
sudo pacman -S --needed "${PACKAGES[@]}"
echo "Installing required packages from AUR using yay..."
yay -S --needed "${AUR_PACKAGES[@]}"

echo "Enabling network manager service..."
sudo systemctl enable --now NetworkManager.service

echo "Enabling bluetooth service..."
sudo systemctl enable --now bluetooth

echo "Enabling firewall service..."
sudo systemctl enable --now ufw

echo "Enabling SwayOSD Libinput Backend service..."
sudo systemctl enable --now swayosd-libinput-backend.service

echo "Installing stow..."
sudo pacman -S --needed stow

symlink_dotfiles "$HOME/.dotfiles" "$HOME"

install_sddm

# copy wallpapers
echo "Copying default wallpapers"
mkdir -p ~/wallpapers
cp -r ./wallpapers/* ~/wallpapers

echo "Adding user to input group..."
sudo usermod -a -G input "$USER"

# Ask about using a laptop
if ask_yes_no "Are you using a laptop?"; then
    yay -S --needed batsignal
    systemctl --user enable batsignal.service
    systemctl --user start batsignal.service
    mkdir -p ~/.config/systemd/user/batsignal.service.d
    printf '[Service]\nExecStart=\nExecStart=batsignal -d 5 -c 15 -w 30 -p' > ~/.config/systemd/user/batsignal.service.d/options.conf
else
    echo "Laptop installation skipped installation skipped."
fi

# Ask about AMD installation
if ask_yes_no "Do you want to install AMD GPU drivers?"; then
    install_amd
else
    echo "AMD GPU installation skipped."
fi

# Ask about restart
if ask_yes_no "Dotfiles successfully installed. Do you want to restart now?"; then
    sudo reboot now
else
    echo "Not restarting. Please restart in order to use the dotfiles."
fi
