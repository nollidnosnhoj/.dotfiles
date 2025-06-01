#!/usr/bin/env bash

pkill -x "wlogout" || wlogout --css "$HOME/.config/wlogout/style.css" --protocol layer-shell
