" 20-mappings.vim -- mapleader, editing/motion maps, quickfix, OSC 52 yank.

" Re-register the runtime's syntaxset autocmd LAST so syntax is applied after
" ftplugin/indent, without paying for a third `syntax on` (~3ms). Copied from
" $VIMRUNTIME/syntax/syntax.vim -- re-check after a major Vim upgrade.
if has('syntax')
  augroup syntaxset
    au! FileType * 0verbose exe "set syntax=" . expand("<amatch>")
  augroup END
endif
" One augroup per file; only this FIRST block carries `autocmd!`.
augroup vimrc_mappings
  autocmd!
  autocmd InsertEnter * set cursorline
  autocmd InsertLeave * set nocursorline
augroup END

let mapleader = " "
let maplocalleader = "\\"
nnoremap <SPACE> <Nop>

augroup vimrc_mappings
  autocmd FileType qf wincmd J
  autocmd FileType qf resize 15
  " Absolute numbers so line N = entry N, matching the 1-9 bookmark jumps (:cc N).
  autocmd FileType qf setlocal nowrap norelativenumber number
  " `p` previews the entry (vim-qf-preview); qf is nomodifiable so p was dead.
  autocmd FileType qf nmap <buffer> p <plug>(qf-preview-open)
augroup END
nnoremap <Leader>op :copen<CR>
nnoremap <Leader>pp :cclose<CR>
command! W write

nnoremap j gj
nnoremap k gk
nnoremap <C-q> ^
vnoremap <C-q> ^
onoremap <C-q> ^

nnoremap <C-e> $
vnoremap <C-e> $
onoremap <C-e> $

" Search the visual selection with * / #. Vim has no Visual-mode * at all.
" \V plus escaping makes the selection match literally, not as a regex.
" Both @s and @" are saved: `let @s = ...` repoints @" at s (:help quote_quote).
" setreg() not `let`, so the register TYPE survives and p still pastes linewise.
" `x` not `v`, so Select mode still replaces on typing. nvim has no equivalent.
function! s:VisualSearch(cmdtype) abort
  let l:reg_s = [getreg('s'), getregtype('s')]
  let l:reg_u = [getreg('"'), getregtype('"')]
  normal! gv"sy
  let @/ = '\V' . substitute(escape(@s, a:cmdtype . '\'), '\n', '\\n', 'g')
  call setreg('s', l:reg_s[0], l:reg_s[1])
  call setreg('"', l:reg_u[0], l:reg_u[1])
endfunction
xnoremap <silent> * :<C-U>call <SID>VisualSearch('/')<CR>/<C-R><C-R>=@/<CR><CR>
xnoremap <silent> # :<C-U>call <SID>VisualSearch('?')<CR>?<C-R><C-R>=@/<CR><CR>

inoremap <C-h> <left>
inoremap <C-j> <down>
inoremap <C-k> <up>
inoremap <C-l> <right>
" Insert-mode word motion. Overrides <C-d> dedent; use <C-t>/<BS> for indent.
inoremap <C-f> <C-o>w
inoremap <C-d> <C-o>b

function! SwitchBuffer(direction)
  " Don't cycle off a fugitive buffer: they are buflisted and bufhidden=delete, so
  " leaving one destroys the :Git split rather than hiding it. gq is the way out.
  " b:fugitive_type ('index'/'temp') rather than &buftype, so quickfix, help, coc
  " trees and terminals are untouched; 'winfixbuf' needs Vim 9.1.0147, we are .0113.
  if exists('b:fugitive_type')
    return
  endif
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

" Tab pages on ]t/[t, since coc owns gt. This displaces unimpaired's ctags maps,
" which it yields cleanly (it skips any lhs already mapped); ]<C-T>/[<C-T> remain.
" Count applied by hand: `:3tabnext` means "go to tab 3", and `:tabnext +3` does
" not wrap. Modulo wraps both ways and for counts above the tab count.
function! s:TabGo(delta) abort
  let l:total = tabpagenr('$')
  if l:total > 1
    execute ((tabpagenr() - 1 + a:delta) % l:total + l:total) % l:total + 1 . 'tabnext'
  endif
endfunction
nnoremap <silent> ]t :<C-U>call <SID>TabGo(v:count1)<CR>
nnoremap <silent> [t :<C-U>call <SID>TabGo(-v:count1)<CR>

" Guarded: :tabclose on the last tab is E784, and this must never quit Vim.
nnoremap <silent> <Leader>tc :<C-U>if tabpagenr('$') > 1 <Bar> tabclose <Bar>
      \ else <Bar> echo 'Only one tab' <Bar> endif<CR>

" Move the current line down/up. unimpaired ships this as ]e/[e, but 50- rebinds
" those to coc diagnostics in NORMAL mode -- so today the move only exists in
" VISUAL mode (x ]e/[e survive, the guard being mode-exact). nvim uses <A-j>/<A-k>,
" unusable here. These get `.`-repeat for free: unimpaired's <Plug>s call
" repeat#set() themselves. `<Plug>` in the rhs is applied even under `noremap`
" (:help map.txt:87), but `nmap` is the honest spelling for a <Plug> target.
nmap <silent> <Leader>j <Plug>(unimpaired-move-down)
nmap <silent> <Leader>k <Plug>(unimpaired-move-up)

" Window resize. Same keys and +-2 step as nvim (LazyVim defaults); nvim's
" <A-hjkl> is unusable here because Alt is unreliable in terminal Vim.
" Ctrl+arrow survives both screen-256color and tmux-256color, verified with the
" raw CSI 1;5 sequences, and stays clear of <C-hjkl> (tmux-navigator).
" A count multiplies the step. Resizes Vim splits only, not the tmux pane.
nnoremap <silent> <C-Up>    :<C-U>execute 'resize +'          . (v:count1 * 2)<CR>
nnoremap <silent> <C-Down>  :<C-U>execute 'resize -'          . (v:count1 * 2)<CR>
nnoremap <silent> <C-Left>  :<C-U>execute 'vertical resize -' . (v:count1 * 2)<CR>
nnoremap <silent> <C-Right> :<C-U>execute 'vertical resize +' . (v:count1 * 2)<CR>
nnoremap <Leader>x :Bclose<CR>
nnoremap <Leader>bd :Bclose<CR>
augroup vimrc_mappings
  autocmd FileType qf nnoremap <buffer> q :q<CR>
augroup END
" NB: these DO work -- Vim remaps a <Plug> rhs even under `noremap`. Don't "fix".
nnoremap <leader>c <Plug>OSCYankOperator
vnoremap <leader>c <Plug>OSCYankVisual
" This Vim is -clipboard with no X display, so 'clipboard=unnamed' is inert.
" Forward yanks to the terminal via OSC 52; no-op on a clipboard-capable Vim.
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
