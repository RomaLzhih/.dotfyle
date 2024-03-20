
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="headline/headline"

plugins=(
zsh-autosuggestions
git
zsh-nvm
zsh-syntax-highlighting
zsh-vi-mode
)

source $ZSH/oh-my-zsh.sh

# Always starting with insert mode for each command line
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

if [ -d "$HOME/bin" ]; then
PATH="$HOME/bin:$PATH"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/neovim/bin:${PATH}"
export PATH="${HOME}/.cargo/bin:${PATH}"

function ya() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
	    cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

