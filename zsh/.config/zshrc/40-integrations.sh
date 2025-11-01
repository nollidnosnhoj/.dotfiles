# Shell integrations
eval $(keychain --eval --quiet id_ed25519 id_rsa)
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"
eval "$(starship init zsh)"