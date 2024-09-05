#!/bin/bash

cur_path=${PWD}

if [[ ${os} == "ubuntu" ]]; then
    sudo apt-get install ninja-build gettext cmake unzip curl build-essential
elif [[ ${os} == "arch" ]]; then
    pacman -S ninja-build gettext cmake unzip curl build-essential
fi

mkdir -p "${HOME}/bin/repos"
cd "${HOME}/bin/repos" || exit
rm -rf neovim
git clone https://github.com/neovim/neovim || exit
cd "neovim" || exit
git checkout release-0.10
make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/neovim"
make install
export PATH="$HOME/neovim/bin:$PATH"

if ! [ -x "$(command -v nvim)" ]; then
    echo "neovim is not installed"
    exit 1
fi

git clone git@github.com:RomaLzhih/neovim_config.git ~/.config/nvim
cd "${cur_path}" || exit
