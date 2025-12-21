if status is-interactive
    keychain --eval id_ed25519 id_rsa | source
end
fzf --fish | source
zoxide init fish | source
mise activate fish | source
starship init fish | source