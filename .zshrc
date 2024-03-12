
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="headline/headline"

plugins=(
zsh-autosuggestions
git
zsh-nvm
zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

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

