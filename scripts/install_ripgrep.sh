#!/bin/bash
# NOTE: ripgrep
path=${pwd}

name="ripgrep"
install=0
cd "${HOME}/bin/repos" || exit
if [ ! -d ${name} ]; then
    git clone https://github.com/BurntSushi/ripgrep --depth=1
    install=1
fi
cd ${name} || exit
git fetch
if [ "$(git rev-parse HEAD)" == "$(git rev-parse @{u})" ] && [ ${install} != 1 ]; then
    echo "rg is up to date"
    exit 1
fi
git pull
cargo build --release
./target/release/rg --version
cd "${HOME}/bin/" || exit
rm -f rg
ln -s "${HOME}/bin/repos/ripgrep/target/release/rg" ~/bin/rg

cd "${path}" || exit
