#!/bin/bash

# Check the current vim version
current_version=$(vim --version | head -n 1 | awk '{print $5}')

# Function to compare versions
version_lt() {
    [ "$1" != "$2" ] && [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n 1)" = "$1" ]
}

# Check if the current version is less than 0.9
if version_lt "$current_version" "0.9"; then
    echo "Vim version is less than 0.9, building from source..."
    mkdir -p "${HOME}/bin/repos"
    cd "${HOME}/bin/repos" || exit
    rm -rf vim
    git clone https://github.com/vim/vim.git || exit
    cd vim || exit
    ./configure --prefix=$HOME/vim
    make
    make install
    export PATH="$HOME/vim/bin:$PATH"
else
    echo "Vim version is 0.9 or greater, no need to build from source."
fi
