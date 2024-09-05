#!/bin/bash
# NOTE: ripgrep
cd "${HOME}/bin/repos" || exit
if [ ! -d "cppcheck" ]; then
    git clone https://github.com/BurntSushi/ripgrep
fi
cd ripgrep || exit
cargo build --release
./target/release/rg --version
cd "${HOME}/bin/" || exit
ln -s "${HOME}/bin/repos/ripgrep/target/release/rg" ~/bin/rg
