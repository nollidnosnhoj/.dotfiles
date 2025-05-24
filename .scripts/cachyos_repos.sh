XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_DIR=$HOME/.dotfiles
TEMP_DIR=$DOTFILES_DIR/.tmp

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

curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o $TEMP_DIR/cachyos-repo.tar.xz
pushd $TEMP_DIR
tar xvf cachyos-repo.tar.xz && pushd cachyos-repo
chmod +x ./cachyos-repo.sh
sudo ./cachyos-repo.sh
popd
popd