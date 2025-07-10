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
while getopts u:i:n:b: flag; do
    case "${flag}" in
    u) kUpdate=${OPTARG} ;;
    i) kInstall=${OPTARG} ;;
    n) kUpdateVim=${OPTARG} ;;
    b) kBackUp=${OPTARG} ;;
    *)
        echo "Usage: $0 [-u update] [-i install] [-n updateVim] [-b backUp]"
        exit 1
        ;;
    esac
done

chmod +x ./scripts/*

# NOTE: BackUp
if [[ ${kBackUp} == 1 ]]; then
    find dotfyles -type f | awk '{sub(/^dotfyles\//, ""); print}' | while IFS= read -r FILE; do
        if [[ -L "${HOME}/${FILE}" ]]; then
            echo ">>>>> Skipping symbolic link ${FILE}..."
            continue
        fi
        echo ">>>>> Backing up ${FILE}..."
        prefix=$(echo "$FILE" | awk 'BEGIN {FS=OFS="/"} {NF--; print}')
        cp "${HOME}/${FILE}" "dotfyles/${prefix}/"
    done
fi

# PERF: Update
if [[ ${kUpdate} == 1 ]]; then
    # NOTE: update plugins
    echo ">>>>> Updating plugins..."
    ./scripts/update_packages.sh "${os}"

    # NOTE: COPY file
    rsync -r --no-perms --no-owner --include="*/" --include=".*" "dotfyles/" "${HOME}/"
    if [[ ${os} == "ubuntu" ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        # git clone --single-branch https://github.com/gpakosz/.tmux.git
        ln -s -f ${HOME}/.tmux/.tmux.conf ${HOME}/.tmux.conf
    else
        rm ${HOME}/.tmux.conf.local
    fi

    # NOTE: neovim
    if [[ ${kUpdateVim} == 1 ]] && [[ "$OSTYPE" != "darwin"* ]]; then
        echo ">>>>> Updating neovim/vim..."
        ./scripts/install_nvim.sh
        ./scripts/install_vim.sh
    fi

    # NOTE: cargo related stuffs
    cargo install-update -a

    source "${HOME}/.zshrc"
    tmux source "${HOME}/.tmux.conf"
fi

# PERF: Install
if [[ ${kInstall} == 1 ]]; then
    # NOTE: shell stuffs
    rsync -r --no-perms --no-owner --include="*/" --include=".*" "dotfyles/" "${HOME}/"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo ">>>>> Installing oh-my-zsh..."
        ./scripts/install_omz.sh
    fi

    export NVM_DIR=$HOME/.nvm
    source "$NVM_DIR/nvm.sh"
    "nvm" install --lts

    # NOTE: cargo
    if ! ./scripts/check_exe.sh "cargo" "1.84.1"; then
        echo ">>>>> Installing rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        rustup update
    fi

    if ! cargo install --list | grep -q "yazi-fm"; then
        echo ">>>>> Installing yazi for file navigation..."
        cargo install --locked yazi-fm yazi-cli
    fi

    source "${HOME}/.zshrc"
    tmux source "${HOME}/.tmux.conf"
    # NOTE: install the dependencies for neovim
    if [[ ${os} == "rocky" ]]; then
        if ! command -v cppcheck &>/dev/null; then
            echo ">>>>> Installing cppcheck..."
            ./scripts/install_cppcheck.sh
        fi
        if ! command -v rg &>/dev/null; then
            echo ">>>>> Installing ripgrep..."
            ./scripts/install_ripgrep.sh
        fi
        if ! command -v lazygit &>/dev/null; then
            echo ">>>>> Installing lazygit..."
            ./scripts/install_lazygit.sh
        fi
    elif [[ ${os} == "ubuntu" ]]; then
        echo ">>>>> Installing clang-tidy cppcheck and rg"
        sudo apt install cppcheck rg clang-tidy

        echo ">>>>> Installing wezterm..."
        git clone https://github.com/RomaLzhih/wezterm-config.git ~/.config/wezterm

        if ! command -v lazygit &>/dev/null; then
            echo ">>>>> Installing lazygit..."
            ./scripts/install_lazygit.sh
        fi
    elif [[ ${os} == "arch" ]]; then
        echo ">>>>> Installing clang-tidy and lazygit..."
        sudo pacman -S clang-tidy lazygit

        echo ">>>>> Installing wezterm..."
        git clone https://github.com/RomaLzhih/wezterm-config.git ~/.config/wezterm
    fi

    source "${HOME}/.zshrc"
    tmux source "${HOME}/.tmux.conf"
fi

echo ">>>>>> Done! Have a good day!"
