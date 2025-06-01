#!/bin/bash

name="neovim"
mkdir -p "${HOME}/bin/repos"
cd "${HOME}/bin/repos" || exit

if [[ ${os} == "ubuntu" ]]; then
    sudo apt-get install ninja-build gettext cmake unzip curl build-essential
elif [[ ${os} == "arch" ]]; then
    pacman -S ninja-build gettext cmake unzip curl build-essential
fi

install=0
if [ ! -d ${name} ]; then
    git clone https://github.com/neovim/neovim || exit
    install=1
fi
cd "neovim" || exit
git checkout master
git fetch
if [ "$(git rev-parse HEAD)" == "$(git rev-parse @{u})" ] && [ ${install} != 1 ]; then
    echo ">>>>> Neovim is up to date"
    exit 1
fi
echo ">>>>> Installing the latest neovim..."
git checkout release-0.10
git pull release-0.10
make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/neovim"
make install
export PATH="$HOME/neovim/bin:$PATH"

mkdir ~/overseer
cp ~/.local/state/nvim/overseer/*.json ~/overseer/

rm -rf ~/.config/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.local/share/nvim
git clone git@github.com:RomaLzhih/neovim_config.git ~/.config/nvim

# nvim --headless -c "MasonInstall clangd clang-format lua-language-server stylua bash-language-server shfmt pyright pylint black codelldb" -c "qall"

mkdir -p ~/.local/state/nvim/overseer
mv ~/overseer/* ~/.local/state/nvim/overseer/
