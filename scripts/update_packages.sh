#!/bin/bash
path=${pwd}
os=$1

"rustup" update

if [[ ${os} == "rocky" ]]; then
    ./scripts/install_cppcheck.sh
    ./scripts/install_ripgrep.sh
    ./scripts/install_lazygit.sh
elif [[ ${os} == "ubuntu" ]]; then
    sudo apt update && sudo apt upgrade -y
    ./scripts/install_cppcheck.sh
    ./scripts/install_lazygit.sh
elif [[ ${os} == "arch" ]]; then
    sudo pacman -Syu
fi

export NVM_DIR=$HOME/.nvm
source "$NVM_DIR/nvm.sh"
"nvm" install --lts

if [[ ${os} == "rocky" ]]; then
    plugins=("nvim")
else
    plugins=("wezterm" "nvim")
fi
for plugin in "${plugins[@]}"; do
    cd "${HOME}/.config/${plugin}" || exit
    git reset --hard
    git pull
done

cd "${path}" || exit
