#!/bin/bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_DIR=$HOME/.dotfiles
TEMP_DIR=$DOTFILES_DIR/_tmp/

STOW_PATHS="fastfetch,gowall,gtk,hypr,kitty,qt,rofi,waybar,waypaper,wlogout,wofi,zsh"

PACKAGES=(
    git firewalld bluez bluez-utils pavucontrol gst-plugin-pipewire pipewire pipewire-alsa
    pipewire-audio pipewire-jack pipewire-pulse wireplumber networkmanager
    network-manager-applet blueman brightnessctl 
    ttf-hack-nerd ttf-jetbrains-mono-nerd ttf-meslo-nerd ttf-noto-nerd noto-fonts ttf-font-awesome
    noto-fonts-emoji thunar swaync grim hyprland kitty polkit-gnome qt5-wayland qt6-wayland 
    slurp wofi rofi-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    nwg-look nwg-displays waybar swww imagemagick hypridle hyprlock hyprshade
    qt5ct qt6ct zsh firefox unzip man-db man-pages udiskie fastfetch
)

AUR_PACKAGES=(
    wlogout papirus-icon-theme-git bibata-cursor-theme-bin gowall swayosd-git clipse 
    grimblast-git waypaper waybar-updates
)

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

# Symlink dotfiles using GNU Stow
symlink_dotfiles() {
    echo "Installing stow..."
    sudo pacman -S --needed stow

    local log_file=$DOTFILES_DIR/stow_arch_output.log

    echo "Symlinking dotfiles from $DOTFILES_DIR to $HOME..."

    for folder in $(echo $STOW_PATHS | sed "s/,/ /g"); do
        echo "stow $folder"
        stow -D $folder
        stow $folder 
        
        # Check exit status
        if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
            echo "Stow failed to symlink files."
            exit
        fi
    done

    echo "Dotfiles symlinked successfully"
}

install_nord_gtk_theme() {
    wget -O $TEMP_DIR/Nordic-darker.tar.xz https://github.com/EliverLara/Nordic/releases/download/v2.2.0/Nordic-darker.tar.xz
    tar -xvf $TEMP_DIR/Nordic-darker.tar.xz -C $TEMP_DIR
    sudo mv $TEMP_DIR/Nordic-darker /usr/share/themes/Nordic-darker
}

enabling_systemctl_services() {
    echo "Enabling network manager service..."
    sudo systemctl enable --now NetworkManager.service

    echo "Enabling bluetooth service..."
    sudo systemctl enable --now bluetooth

    echo "Enabling firewall service..."
    sudo systemctl enable --now firewalld.service

    echo "Enabling SwayOSD Libinput Backend service..."
    sudo systemctl enable --now swayosd-libinput-backend.service
}

enabling_wallpapers() {
    local wallpaper_dir = "$HOME/wallpapers"
    if [ ! -d $wallpaper_dir ]; then
        mkdir -p $wallpaper_dir
    fi
    cp -r $DOTFILES_DIR/wallpapers/* $wallpaper_dir
    
    local default_wallpaper_path = $wallpaper_dir/default_wallpaper.jpg
    
    if [ -f $default_wallpaper_path ]; then
        echo "Running wallpaper script on $default_wallpaper_path"
        $XDG_CONFIG_HOME/hypr/scripts/wallpaper.sh $default_wallpaper_path
    fi
}

main() {
    # checks if the current working directory is the correct dotfiles path...
    if [ $(pwd) != $DOTFILES_DIR ]; then
        echo "The current directory must be in $DOTFILES_DIR"
        exit 1
    fi

    # create temp directory if not exist
    if [ ! -d $TEMP_DIR ]; then
        echo "Creating temp directory"
        mkdir -p $TEMP_DIR
    fi

    echo "Installing my arch linux dotfiles..."

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

    echo "Modifying scripts' permissions for execution"
    chmod +x $DOTFILES_DIR/.config/hypr/scripts/*.sh

    symlink_dotfiles
    enabling_wallpapers

    echo "Adding user to input group..."
    sudo usermod -a -G input "$USER"

    # Ask about using a laptop
    if ask_yes_no "Are you using a laptop?"; then
        yay -S --needed batsignal
        systemctl --user enable batsignal.service
        systemctl --user start batsignal.service
        mkdir -p $XDG_CONFIG_HOME/systemd/user/batsignal.service.d
        printf '[Service]\nExecStart=\nExecStart=batsignal -d 5 -c 15 -w 30 -p' > $XDG_CONFIG_HOME/systemd/user/batsignal.service.d/options.conf
    else
        echo "Laptop installation skipped installation skipped."
    fi

    echo "Cleaning temp directory"
    rm -rf $TEMP_DIR

    # Ask about restart
    if ask_yes_no "Dotfiles successfully installed. Do you want to restart now?"; then
        sudo reboot now
    else
        echo "Not restarting. Please restart in order to use the dotfiles."
    fi
}

main
