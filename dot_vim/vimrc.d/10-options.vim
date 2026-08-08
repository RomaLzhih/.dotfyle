" ============================================================================
" 10-options.vim
" ----------------------------------------------------------------------------
" Core editor options: numbering, indentation, search, clipboard,
" bracketed paste, autoread.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" -------------------------------VIM CONFIG---------------------------------
" Swap file
set directory=$HOME/.local/state/vim/swap// | call mkdir(&directory, "p")

" Security
set modelines=0

" Show line numbers
set number

" Show file stats
set ruler
set relativenumber

" Encoding
set encoding=utf-8

" Whitespace
set wrap
" set textwidth=80
set ignorecase
set smartcase
set formatoptions=tcqrn1
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
" set nonumber
set noshiftround
set mouse=a
set clipboard=unnamed,unnamedplus

" Bracketed paste: make terminal pastes (e.g. Cmd+V) insert literally instead of
" getting re-indented (staircase) or auto-closed by delimitMate. vim leaves these
" empty under tmux/screen ($TERM=screen-256color), so enable them explicitly.
if empty(&t_BE) && !has('gui_running')
  let &t_BE = "\<Esc>[?2004h"
  let &t_BD = "\<Esc>[?2004l"
  let &t_PS = "\<Esc>[200~"
  let &t_PE = "\<Esc>[201~"
endif

" Cursor motion
set scrolloff=3
set backspace=indent,eol,start
set belloff=all
set timeoutlen=200
set ttimeoutlen=200
runtime! macros/matchit.vim

" Allow hidden buffers
set hidden

" Rendering
set ttyfast
set guicursor+=a:blinkon0

" Status bar
set laststatus=2

" Last line
set showmode
set showcmd


" Searching
set hlsearch
set incsearch
set showmatch

" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬

" auto read file when changed
set autoread
" These live in an augroup with `autocmd!` because a BARE autocmd appends rather
" than replaces: every `:source $MYVIMRC` used to add another copy (checktime went
" from 4 event entries to 12 after two re-sources).
" One augroup per file; only the FIRST block in a file carries `autocmd!`.
augroup vimrc_options
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
  autocmd FileChangedShellPost *
              \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
  " Re-equalize split windows when the terminal/vim is resized
  autocmd VimResized * wincmd =
augroup END
