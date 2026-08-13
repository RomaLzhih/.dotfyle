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
" 'timeoutlen' (above) is the <leader>-mapping window and is a deliberate choice.
" 'ttimeoutlen' is a DIFFERENT thing: the window in which the rest of a multi-byte
" terminal key code must arrive. It is also what insert-mode <Esc> waits out, because
" <Esc> is the prefix of every arrow/function-key code.
"
" Measured (pty, 200x50, kernel/fork.c, real config): pressing <Esc> in insert mode
" emits a small cosmetic burst at 25ms (a fixed Vim constant, not tunable), then
" nothing until ttimeoutlen expires -- only then does Vim actually leave insert mode
" and run InsertLeave. The real repaint (cursorline off + airline's mode block, ~1.2KB)
" landed at 227ms with ttimeoutlen=200 and at 57ms with 30. That is ~170ms off the
" most-pressed key in a modal editor. tmux's own `escape-time` stacks on top of this;
" ~/.tmux.conf was moved 50 -> 10 (tmux 3.5a's own default) for the same reason.
"
" 'ttimeout' is already on -- defaults.vim sets it; do not re-add it.
" Raise this back toward 50-100 if arrow keys or SGR mouse reports ever arrive split
" (only plausible over a high-latency link; tmux delivers whole sequences in one write).
set ttimeoutlen=30
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
" 'showmatch' briefly jumps the cursor to the matching bracket when one is inserted.
" With the default 'matchtime'=5 that is 500ms of the cursor sitting somewhere else
" every time you type ')' or '}' and then pause to think (measured: the return burst
" lands at 510ms; at matchtime=1 it lands at 109ms). It costs nothing while typing
" continuously -- 'cpoptions' has no 'm' flag here, so the next keystroke cancels it.
" Kept rather than dropped because the jump is useful; shortened to 100ms. The runtime
" matchparen plugin highlights the same pair persistently either way.
set showmatch
set matchtime=1

" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬

" ----------------------------LARGE FILES-----------------------------------
" Mirror of the nvim config's BigCppTune (lua/config/autocmds.lua): past 3000 lines
" or 512KB, switch off the per-idle/per-redraw extras. Same thresholds, but applied
" to every filetype rather than just c/cpp -- the costs below are not C-specific.
"
" Scope note, from measuring rather than assuming: most of what felt like "big file
" slowness" here was NOT size-dependent at all. CursorHold cost 3.1ms on an 11336-line
" kernel file and 3.0ms on a 78-line one, and 2.6ms of that was vim-signature's
" periodic sign refresh -- fixed globally in 30-plugin-config.vim, not here.
" What genuinely does scale with file size is below.
"
" What is deliberately NOT disabled, matching nvim: the language server stays
" attached, so completion, diagnostics and goto keep working on big files.
let g:big_file_lines = 3000
let g:big_file_bytes = 512 * 1024

function! s:BigFileCheck() abort
  let l:size = getfsize(expand('%'))
  if line('$') <= g:big_file_lines && (l:size <= 0 || l:size <= g:big_file_bytes)
    return
  endif
  let b:big_file = 1
  " Cap regex syntax per line. Does nothing for ordinary source (kernel C tops out
  " around 100 columns) but bounds the pathological case: generated, minified or
  " single-line-JSON files, which is where syntax cost actually explodes.
  setlocal synmaxcol=200
  " indentLine is conceal-based, so it re-evaluates on every redraw of every line.
  let b:indentLine_enabled = 0
endfunction

augroup vimrc_bigfile
  autocmd!
  autocmd BufReadPost * call s:BigFileCheck()
augroup END

" auto read file when changed
set autoread
" These live in an augroup with `autocmd!` because a BARE autocmd appends rather
" than replaces: every `:source $MYVIMRC` used to add another copy (checktime went
" from 4 event entries to 12 after two re-sources).
" One augroup per file; only the FIRST block in a file carries `autocmd!`.
augroup vimrc_options
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
  " `redraw` first, or this blocks on a hit-enter prompt every single reload: the
  " autoread reload has already printed its own `"file" 4L, 20B` line, and a second
  " message with cmdheight=1 is what triggers "Press ENTER". The redraw clears the
  " pending message so only this one is left, and nothing has to be acknowledged.
  " Measured alternatives that do NOT work: shortmess+=F still prompts (it does not
  " suppress the reload's file info), and deferring the echo with timer_start()
  " loses the message altogether.
  autocmd FileChangedShellPost * redraw
              \ | echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
  " Re-equalize split windows when the terminal/vim is resized
  autocmd VimResized * wincmd =
augroup END

" Utility/side windows hold one record per line, so the global `set wrap` above
" turns them into ragged paragraphs where a single long entry spills over the
" next few rows and line N is no longer entry N.
" Deliberately an explicit filetype list rather than `if &buftype !=# ''`: coc's
" hover and documentation windows are buftype=nofile too, and they hold prose
" that must keep wrapping or it gets cut off at the right edge. Prose is also
" why `help` and `gitcommit` are absent -- help is hand-wrapped to ~78 columns,
" so nowrap only truncates it in a split narrower than that.
" Quickfix is not listed -- 20-mappings.vim already gives it nowrap alongside
" the absolute-number setting that the 1-9 bookmark jumps depend on.
" No `autocmd!` here: this file's first vimrc_options block above owns the clear.
augroup vimrc_options
  autocmd FileType bufexplorer,startify,peekaboo,fugitive,git,netrw,vim-plug
        \ setlocal nowrap
  " Terminals (floaterm, yazi) draw TUIs sized to the exact window width, so a
  " line that does overflow is corruption rather than content worth wrapping.
  autocmd TerminalWinOpen * setlocal nowrap
augroup END
