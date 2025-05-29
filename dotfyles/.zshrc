export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="headline/headline"

# ZSH_THEME="typewritten/typewritten"
# TYPEWRITTEN_PROMPT_LAYOUT="singleline_verbose"
# TYPEWRITTEN_CURSOR="block"
# TYPEWRITTEN_COLOR_MAPPINGS="primary:blue;secondary:white;accent:yellow"

plugins=(
zsh-autosuggestions
git
zsh-nvm
zsh-syntax-highlighting
zsh-vi-mode
)

source $ZSH/oh-my-zsh.sh

HEADLINE_USER_PREFIX=' '
HEADLINE_HOST_PREFIX=' '
HEADLINE_PATH_PREFIX=' '
HEADLINE_BRANCH_PREFIX=' '
# Always starting with insert mode for each command line
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk

if [ -d "$HOME/bin" ]; then
PATH="$HOME/bin:$PATH"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.local/share/nvim/mason/bin:${PATH}"
export PATH="${HOME}/neovim/bin:${PATH}"
export PATH="${HOME}/vim/bin:${PATH}"
export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export GEMINI_API_KEY=$(cat "$HOME/.gemini_api_key")

alias lg="lazygit"
alias c++="clang++"

function ya() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
	    cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
else
# Get the distribution name
DISTRO=$(grep '^ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
# Run commands based on the distribution
if [[ "$DISTRO" == "ubuntu" ]]; then
    # fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc
    # pokemon-colorscripts --no-title -s -r #without fastfetch
    pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
elif [[ "$DISTRO" == "arch" ]]; then
    pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
elif [[ "$DISTRO" == "rocky" ]]; then
else
fi
fi

# Automatically set the highest Python version
HIGHEST_PYTHON=$(ls /usr/bin/python3* | grep -Eo 'python3\.[0-9]+' | sort -V | tail -1)
alias python="/usr/bin/$HIGHEST_PYTHON"
alias python3="/usr/bin/$HIGHEST_PYTHON"
