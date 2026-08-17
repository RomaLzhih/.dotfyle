" 10-options.vim -- core editor options, large-file tuning, autoread.

set directory=$HOME/.local/state/vim/swap// | call mkdir(&directory, "p")
set modelines=0
set number
set ruler
set relativenumber
set encoding=utf-8

" Whitespace / search behaviour
set wrap
" set textwidth=80
set ignorecase
set smartcase
set formatoptions=tcqrn1
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set noshiftround
set mouse=a
set clipboard=unnamed,unnamedplus

" Bracketed paste, so terminal pastes insert literally instead of being
" re-indented or auto-closed. Vim leaves these empty under tmux/screen.
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
" timeoutlen = the <leader> window. ttimeoutlen is unrelated: it is how long a
" multi-byte key code may take, and so what insert-mode <Esc> waits out.
" 200 -> 30 moved the InsertLeave repaint from 227ms to 57ms. Raise toward 50-100
" only if key codes ever arrive split. 'ttimeout' is already on via defaults.vim.
set timeoutlen=200
set ttimeoutlen=30
runtime! macros/matchit.vim

set hidden
set ttyfast
set guicursor+=a:blinkon0
set laststatus=2
set showmode
set showcmd

set hlsearch
set incsearch
" showmatch is kept but shortened: at the default matchtime=5 the cursor sits on
" the matching bracket for 500ms every time you type ')' and pause.
set showmatch
set matchtime=1

set listchars=tab:▸\ ,eol:¬

" ---- large files ----
" Mirrors nvim's BigCppTune thresholds, but for every filetype. The LSP stays
" attached on purpose. Note most "big file slowness" here was size-independent and
" fixed in 30- instead; only the two settings below actually scale with size.
let g:big_file_lines = 3000
let g:big_file_bytes = 512 * 1024

function! s:BigFileCheck() abort
  let l:size = getfsize(expand('%'))
  if line('$') <= g:big_file_lines && (l:size <= 0 || l:size <= g:big_file_bytes)
    return
  endif
  let b:big_file = 1
  " Bounds the pathological case: generated/minified/one-line-JSON files.
  setlocal synmaxcol=200
  " indentLine is conceal-based, so it re-evaluates every line on every redraw.
  let b:indentLine_enabled = 0
endfunction

augroup vimrc_bigfile
  autocmd!
  autocmd BufReadPost * call s:BigFileCheck()
augroup END

set autoread
" One augroup per file; only this FIRST block carries `autocmd!`. A bare autocmd
" appends, so re-sourcing used to stack duplicate handlers.
augroup vimrc_options
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
  " `redraw` first or this hits a Press-ENTER prompt every reload: autoread has
  " already printed its own file-info line, and a second message with cmdheight=1
  " triggers the prompt. shortmess+=F does not help; deferring loses the message.
  autocmd FileChangedShellPost * redraw
              \ | echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
  autocmd VimResized * wincmd =
augroup END

" Side windows hold one record per line, so global `wrap` makes line N stop being
" entry N. An explicit filetype list, not `&buftype !=# ''`: coc's hover windows are
" nofile too and hold prose. help/gitcommit are prose as well. qf is done in 20-.
augroup vimrc_options
  autocmd FileType bufexplorer,startify,peekaboo,fugitive,git,netrw,vim-plug
        \ setlocal nowrap
  " TUIs in terminals are sized to the window, so an overflowing line is corruption.
  autocmd TerminalWinOpen * setlocal nowrap
augroup END
