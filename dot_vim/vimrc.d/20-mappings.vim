" ============================================================================
" 20-mappings.vim
" ----------------------------------------------------------------------------
" mapleader and general editing/motion mappings, quickfix window
" behaviour, and clipboard yanking over OSC 52.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" ---------------------------------------MAPPING-----------------------------------
" Syntax is already on by here: /etc/vimrc runs `syntax on`, and plug#end() falls
" back to `syntax enable` when it is not. A third `syntax on` re-ran the whole
" syncolor/synload chain for ~3ms. But it was not pure waste: its side effect was
" re-registering the runtime's `syntaxset` autocmd LAST, so syntax is applied
" AFTER ftplugin/indent -- the order $VIMRUNTIME/defaults.vim produces and that
" runtime ftplugins depend on (ftplugin/sh.vim reads b:is_bash, which syntax/sh.vim
" sets; without this, K in a shell script stops running `man`).
" So: keep the ordering, drop the re-parse. Copied from $VIMRUNTIME/syntax/syntax.vim
" -- re-check after a major Vim upgrade.
if has('syntax')
  augroup syntaxset
    au! FileType * 0verbose exe "set syntax=" . expand("<amatch>")
  augroup END
endif
" `filetype plugin indent on` is already done by plug#end() in 00-plugins.vim.
" One augroup per file, so `:source $MYVIMRC` replaces these rather than
" appending duplicates. `autocmd!` appears ONCE per file, here
" -- the later vimrc_mappings blocks must NOT repeat it or they would wipe these.
augroup vimrc_mappings
  autocmd!
  autocmd InsertEnter * set cursorline
  autocmd InsertLeave * set nocursorline
augroup END

" Pick a leader key
let mapleader = " "
let maplocalleader = "\\"
nnoremap <SPACE> <Nop>
" NOTE: no `autocmd!` here -- it would wipe the InsertEnter/InsertLeave pair above.
augroup vimrc_mappings
  autocmd FileType qf wincmd J
  autocmd FileType qf resize 15
  " Quickfix display: don't wrap long entries (global 'set wrap' is on), and show
  " absolute line numbers instead of relative -- so the visible number is the entry
  " number (line N = entry N), matching the 1-9 jump maps (:cc N).
  autocmd FileType qf setlocal nowrap norelativenumber number
augroup END
" Quickfix list: op opens it, pp closes it (q also closes it from inside).
nnoremap <Leader>op :copen<CR>
nnoremap <Leader>pp :cclose<CR>
command! W write

" Edit operation
nnoremap j gj
nnoremap k gk
nnoremap <C-q> ^
vnoremap <C-q> ^
onoremap <C-q> ^

nnoremap <C-e> $
vnoremap <C-e> $
onoremap <C-e> $

inoremap <C-h> <left>
inoremap <C-j> <down>
inoremap <C-k> <up>
inoremap <C-l> <right>
" Word-wise motion in insert mode: <C-f> = next word (like w), <C-d> = previous
" word (like b). <C-o> runs one normal-mode command and returns to insert.
" (Note: this overrides insert-mode <C-d> dedent; use <C-t>/<BS> to adjust indent.)
inoremap <C-f> <C-o>w
inoremap <C-d> <C-o>b
" Skip quickfix buffer when switching
function! SwitchBuffer(direction)
  let start_buf = bufnr('%')
  let buf = start_buf
  
  while 1
    if a:direction == 'next'
      bnext
    else
      bprevious
    endif
    
    let buf = bufnr('%')
    
    " Stop if we're not in quickfix or location list
    if &buftype != 'quickfix'
      break
    endif
    
    " Prevent infinite loop if all buffers are quickfix
    if buf == start_buf
      break
    endif
  endwhile
endfunction

nnoremap <Tab> :call SwitchBuffer('next')<CR>
nnoremap <S-Tab> :call SwitchBuffer('prev')<CR>
nnoremap <Leader>x :Bclose<CR>
nnoremap <Leader>bd :Bclose<CR>
augroup vimrc_mappings
  autocmd FileType qf nnoremap <buffer> q :q<CR>
augroup END
" NB: these two DO work. Vim special-cases a <Plug> right-hand side and remaps it
" even under `noremap`, so they are live -- don't "fix" them to nmap/vmap, and
" don't delete them as dead.
nnoremap <leader>c <Plug>OSCYankOperator
vnoremap <leader>c <Plug>OSCYankVisual
" Make plain y sync to the system clipboard. This Vim is built without clipboard
" support (-clipboard) and the devserver has no X display, so 'clipboard=unnamed'
" is inert and y never reaches the local clipboard. Forward every yank to the
" terminal's clipboard via OSC 52 (vim-oscyank). Gated on clipboard being
" unavailable, so it's a no-op on a clipboard-capable Vim.
if !has('nvim') && !has('clipboard_working')
  let s:osc_yank_regs = ['', '+', '*']
  function! s:OSCYankOnYank(event) abort
    if a:event.operator ==# 'y' && index(s:osc_yank_regs, a:event.regname) != -1
      call OSCYankRegister(a:event.regname)
    endif
  endfunction
  augroup OSCYankOnYank
    autocmd!
    autocmd TextYankPost * call s:OSCYankOnYank(v:event)
  augroup END
endif
" (Removed two dead mappings:
"   <leader>hc yyP<Plug>CommentaryLinej -- unconditionally shadowed by
"     `nmap <Leader>hc <Plug>BookmarkClear` in 30-plugin-config.vim, which is
"     sourced later, so this could never fire.
"   <leader>tp :TransparentToggle<CR>   -- no installed plugin defines that
"     command; the mapping just errored.)

