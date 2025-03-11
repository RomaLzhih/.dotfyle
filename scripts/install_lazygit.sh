#!/bin/bash
path=${pwd}

if ! command -v go &>/dev/null; then
    export PATH=$HOME/bin/repos/go/bin:$PATH
fi

go install github.com/jesseduffield/lazygit@latest
