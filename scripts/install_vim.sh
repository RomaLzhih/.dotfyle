#!/bin/bash
# Check if the current version is less than 0.9
path=${pwd}
mkdir -p "${HOME}/bin/repos"
cd "${HOME}/bin/repos" || exit
name="vim"
install=0
if [ ! -d ${name} ]; then
    git clone https://github.com/vim/vim.git --depth=1 || exit
    install=1
fi
cd vim || exit
git fetch
if ["$(git rev-parse HEAD)" == "$(git rev-parse @{u})"] && [ ${install} != 1 ]; then
    echo "Vim is up to date"
    exit 1
fi
git pull
./configure --prefix="$HOME/vim"
make
make install
export PATH="$HOME/vim/bin:$PATH"
cd "${path}" || exit
