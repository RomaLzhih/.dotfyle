#!/bin/bash
#POSIX
# set -o xtrace

# NOTE: get os name
os=""
if [ -r /etc/os-release ]; then
    os="$(. /etc/os-release && echo "$ID")"
fi
echo "OS Release: ${os}"

kUpdate=0
kInstall=0
kBackUp=0
kUpdateVim=0
while getopts u:i:b:n: flag; do
    case "${flag}" in
    u) kUpdate=${OPTARG} ;;
    i) kInstall=${OPTARG} ;;
    n) kUpdateVim=${OPTARG} ;;
    b) kBackUp=${OPTARG} ;;
    *) echo "do nothing..." ;;
    esac
done

chmod +x ./scripts/*

# NOTE: BackUp
if [[ ${kBackUp} == 1 ]]; then
    find dotfyles -type f | awk '{sub(/^dotfyles\//, ""); print}' | while IFS= read -r FILE; do
        # rsync -a --include=".*" "${HOME}/${FILE}" "dotfyles/"
        prefix=$(echo "$FILE" | awk 'BEGIN {FS=OFS="/"} {NF--; print}')
        echo $prefix
        cp "${HOME}/${FILE}" "dotfyles/${prefix}/"
    done
fi

# PERF: Update
if [[ ${kUpdate} == 1 ]]; then
    # NOTE: COPY file
    rsync -a --include="*/" --include=".*" "dotfyles/" "${HOME}/"

    # NOTE: neovim
    if [[ ${kUpdateVim} == 1 ]]; then
        ./scripts/install_nvim.sh
        ./scripts/install_vim.sh
    fi

    # NOTE: neovim dependencies
    if [[ ${os} == "rocky" ]]; then
        cd "${HOME}" || exit

        export NVM_DIR=$HOME/.nvm
        source "$NVM_DIR/nvm.sh"
        nvm install lts --reinstall-packages-from=current

        python3 -m pip install --upgrade pip setuptools wheel
        python3 -m pip install clang-tidy -U
        python3 -m pip install cpplint -U
        python3 -m pip install black -U
        python3 -m pip install pandas-stubs -U
        python3 -m pip install pynvim -U

        ./scripts/install_cppcheck.sh
        ./scripts/install_ripgrep.sh

    elif [[ ${os} == "ubuntu" ]]; then
        sudo apt update && sudo apt upgrade -y
    elif [[ ${os} == "arch" ]]; then
        sudo pacman -Syu
    fi

    # NOTE: cargo related stuffs
    if cargo install --list | grep -q 'cargo-update'; then
        cargo install-update -a
    else
        cargo install cargo-update
        cargo install-update -a
    fi

    source "${HOME}/.zshrc"
    tmux source "${HOME}/.tmux.conf"
fi

# PERF: Install
if [[ ${kInstall} == 1 ]]; then
    # NOTE: shell stuffs
    rsync -a --include="*/" --include=".*" "dotfyles/" "${HOME}/"
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "OMZ installed"
    else
        ./scripts/install_omz.sh
    fi

    export NVM_DIR=$HOME/.nvm
    source "$NVM_DIR/nvm.sh"
    "nvm" install --lts

    # NOTE: cargo
    if ./scripts/check_exe.sh "cargo" "1.80.0"; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        rustup update
    fi

    if ! cargo install --list | grep -q "yazi-fm"; then
        cargo install --locked yazi-fm yazi-cli
    fi

    # NOTE: zoxide
    if command -v zoxide &>/dev/null; then
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    # NOTE: install nvim/vim
    mkdir -p "${HOME}/bin/repos"
    if [[ ${kUpdateVim} == 1 ]]; then
        if ./scripts/check_exe.sh "nvim" "0.10.0"; then
            ./scripts/install_nvim.sh
        fi
        if ./scripts/check_exe.sh "vim" "9.0"; then
            ./scripts/install_vim.sh
        fi
    fi

    # NOTE: install the dependencies for neovim
    if [[ ${os} == "rocky" ]]; then
        cd "${HOME}" || exit
        # NOTE: python env
        python3 -m venv .venv
        source .venv/bin/activate
        python3 -m pip --version
        python3 -m pip install --upgrade pip setuptools wheel
        python3 -m pip install clang-tidy
        python3 -m pip install pandas-stubs
        python3 -m pip install pynvim

        # NOTE: build from source
        mkdir -p "${HOME}/bin/repos"

        if ! command -v cppcheck &>/dev/null; then
            ./scripts/install_cppcheck.sh
        fi
        if ! command -v rg &>/dev/null; then
            ./scripts/install_ripgrep.sh
        fi

    elif [[ ${os} == "ubuntu" ]]; then
        sudo apt install clang-tidy nodejs
        git clone https://github.com/RomaLzhih/wezterm-config.git ~/.config/wezterm
    elif [[ ${os} == "arch" ]]; then
        sudo pacman -S clang-tidy nodejs
        git clone https://github.com/RomaLzhih/wezterm-config.git ~/.config/wezterm
    fi

    source "${HOME}/.zshrc"
    tmux source "${HOME}/.tmux.conf"
fi

echo ">>>>>> Done! Have a good day!"
