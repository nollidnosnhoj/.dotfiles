#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_DIR=$HOME/.dotfiles
TEMP_DIR=$DOTFILES_DIR/.tmp
LOG_FILE="arch_install_$(date '+%Y-%m-%d %H:%M:%S').log"

STOW_PATHS="fastfetch,gowall,gtk,hypr,kitty,mise,oh-my-posh,qt,swaync,walker,waybar,waypaper,wlogout,zsh"

CORE_PACKAGES=(
    archlinux-keyring
    curl
    wget
    unzip
    bluez
    bluez-utils
    firewalld
    pavucontrol
    gst-plugin-pipewire
    pipewire
    pipewire-alsa
    pipewire-audio
    pipewire-jack
    pipewire-pulse
    wireplumber
    networkmanager
    brightnessctl
    playerctl
    uwsm
)

FONT_PACKAGES=(
    ttf-hack-nerd
    ttf-jetbrains-mono-nerd
    ttf-meslo-nerd
    ttf-noto-nerd
    noto-fonts
    otf-font-awesome
    noto-fonts-emoji
)

HYPR_PACKAGES=(
    kitty
    hyprland
    hyprpolkitagent
    qt5-wayland
    qt6-wayland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-desktop-portal
    xdg-utils
)

HYPR_EXTRA_PACKAGES=(
    # hyprland extras
    network-manager-applet
    blueman
    thunar
    swaync
    grim
    slurp
    swww
    nwg-look
    nwg-displays
    waybar
    imagemagick
    hypridle
    hyprlock
    qt5ct
    qt6ct
    kvantum
    zsh
    man-db
    man-pages
    udiskie
    fastfetch

    # thunar extensions
    thunar-volman 
    tumbler
    ffmpegthumbnailer 
    thunar-archive-plugin
    xarchiver
)

AUR_PACKAGES=(
    wlogout
    gowall
    swayosd-git
    clipse 
    grimblast-git
    walker-bin
    waypaper
    waybar-updates
    vscodium-bin
    zen-browser-bin
)

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

REMOVED_PACKAGES=(
    dunst
    dolphin
    polkit-kde-agent
    wofi
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
        sudo pacman -S --needed --noconfirm git base-devel
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
stow_dotfiles() {
    echo "Installing stow..."
    sudo pacman -S --needed --noconfirm stow

    local log_file=$DOTFILES_DIR/stow_arch_output.log

    echo "Symlinking dotfiles from $DOTFILES_DIR to $HOME..."

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

    echo "Dotfiles symlinked successfully"
}

install_gtk_icons_and_themes() {
    echo "Installing GTK icons..."
    yay -S --needed --noconfirm papirus-icon-theme-git bibata-cursor-theme-bin 

    if [ -d /usr/share/themes/Nordic ]; then
        echo "GTK theme already installed..."
    else
        echo "Installing GTK theme..."
        wget -O $TEMP_DIR/Nordic.tar.xz https://github.com/EliverLara/Nordic/releases/download/v2.2.0/Nordic.tar.xz
        tar -xvf $TEMP_DIR/Nordic.tar.xz -C $TEMP_DIR
        sudo mv $TEMP_DIR/Nordic /usr/share/themes/Nordic
        gsettings set org.gnome.desktop.interface gtk-theme "Nordic"
        gsettings set org.gnome.desktop.wm.preferences theme "Nordic"
    fi
}

enabling_services() {
    echo "Enabling network manager service..."
    sudo systemctl enable --now NetworkManager.service

    echo "Enabling bluetooth service..."
    sudo systemctl enable --now bluetooth

    echo "Enabling firewall service..."
    sudo systemctl enable --now firewalld.service

    echo "Enabling SwayOSD Libinput Backend service..."
    sudo systemctl enable --now swayosd-libinput-backend.service
}

install_greetd() {
    echo "Installing greetd login manager"
    sudo pacman -S --needed --noconfirm greetd greetd-tuigreet

    echo "Copying configuration to /etc/greetd/config.toml"
    sudo cp -rf $DOTFILES_DIR/greetd/config.toml /etc/greetd/config.toml

    echo "Enabling greetd service"
    sudo systemctl enable greetd.service
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

    echo "Copying Git configuration..."
    if [ ! -f $HOME/.gitconfig ]; then
        rm $HOME/.gitconfig
    fi
    cp ./git/.gitconfig $HOME/.gitconfig

    if ! command -v git &> /dev/null; then
        echo "Git was not installed... Installing git..."
        sudo pacman -S --needed --noconfirm git base-devel
    fi

    echo "Configuring pacman..."
    sudo sed -i 's/^#Color/Color/; s/^#VerbosePkgLists/VerbosePkgLists/; s/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

    enable_multilib
    install_yay
    enable_chaotic_aur

    if ask_yes_no "Add cachy_os repositories? [NOTE] This would modify pacman."; then
        source ./.scripts/cachyos_repos.sh
    fi

    echo "Reducing package compression time..."
    sudo sed -i 's/COMPRESSZST=(zstd -c -T0 --ultra -20 -)/COMPRESSZST=(zstd -c -T0 --fast -)/' /etc/makepkg.conf

    echo "Installing core packages using pacman..."
    sudo pacman -S --needed --noconfirm "${CORE_PACKAGES[@]}"

    echo "Installing hyprland packages..."
    sudo pacman -S --needed --noconfirm "${HYPR_PACKAGES[@]}"

    echo "Installing additional hyprland packages..."
    sudo pacman -S --needed --noconfirm "${HYPR_EXTRA_PACKAGES[@]}"

    echo "Installing font packages..."
    sudo pacman -S --needed --noconfirm "${FONT_PACKAGES[@]}"

    echo "Installing AUR packages..."
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

    echo "Installing development packages..."
    yay -S --needed --noconfirm "${DEV_PACKAGES[@]}"

    echo "Removing packages from archinstall"
    sudo pacman -Rs "${REMOVED_PACKAGES[@]}"

    echo "Modifying scripts' permissions for execution"
    chmod +x $DOTFILES_DIR/.config/hypr/scripts/*.sh

    stow_dotfiles
    install_gtk_icons_and_themes

    echo "Setting up wallpapers directory..."
    mkdir -p $HOME/Pictures/Wallpapers
    cp -r $DOTFILES_DIR/wallpapers/. $HOME/Pictures/Wallpapers

    echo "Adding user to input group..."
    sudo usermod -a -G input "$USER"
    sudo gpasswd -a $USER input

    echo "Installing tools using mise..."
    mise install

    echo "Installing neovim configuration..."
    git clone https://github.com/nollidnosnhoj/kickstart.nvim $HOME/.config/nvim
    echo "Run 'nvim' to install neovim plugins."

    echo "Switching to zsh..."
    chsh -s /bin/zsh

    echo "Installing extra packages..."
    sudo pacman -S --needed "${DEV_PACKAGES[@]}"

    enabling_services
    install_greetd

    # Ask about using a laptop
    if ask_yes_no "Are you using a laptop?"; then
        yay -S --needed --noconfirm batsignal fprintd pam-fprint-grosshack libinput-gestures
        systemctl --user enable batsignal.service
        systemctl --user start batsignal.service
        mkdir -p $XDG_CONFIG_HOME/systemd/user/batsignal.service.d
        printf '[Service]\nExecStart=\nExecStart=batsignal -d 5 -c 15 -w 30 -p' > $XDG_CONFIG_HOME/systemd/user/batsignal.service.d/options.conf

        echo "Autostarting Libinput Gestures"
        libinput-gestures-setup autostart
    else
        echo "Laptop installation skipped installation skipped."
        sleep 1
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

if [ ! -f ./arch_install.log ]; then
    touch ./arch_install.log
fi
main | tee arch_install.log
