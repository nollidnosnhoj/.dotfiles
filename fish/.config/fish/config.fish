# loop through the ./configs fish script and source them
for config in ~/.config/fish/configs/*.fish
    source $config
end