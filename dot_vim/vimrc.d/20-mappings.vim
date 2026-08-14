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
  " Preview the entry under the cursor in a popup (vim-qf-preview, lazy-loaded by
  " the 'for': 'qf' trigger in 00-plugins.vim). Safe key: `p` in a quickfix window
  " is nomodifiable, so it only ever errored before.
  autocmd FileType qf nmap <buffer> p <plug>(qf-preview-open)
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

" Search for the visual selection with * / #. Vim has no Visual-mode * at all -- it
" is a Normal-mode command only, so on a selection the key is simply unbound and
" does nothing. This makes it search the selected text rather than the word under
" the cursor, which is the useful half of :help star for multi-word or
" punctuation-heavy text.
" \V (very nomagic) plus escaping the delimiter and backslashes means the selection
" matches literally, so `foo->bar[0]` or `a.b.c` are not treated as a regex.
" Both register s AND the unnamed register are saved/restored: selecting and hitting
" * must not clobber what you were about to put. Restoring s alone is not enough --
" `let @s = ...` repoints the unnamed register at s (:help quote_quote), so @" ends
" up holding s's contents rather than the yank you had. setreg() rather than `let`
" so the register TYPE survives too, otherwise a linewise yank comes back charwise
" and the next p pastes inline instead of on its own line.
" `x` not `v`: Select mode should keep replacing the selection when you type.
" NOTE: nvim has no visual * either (no LazyVim default, no plugin), so this is
" vim-only for now; say the word and it can be mirrored there.
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
" Word-wise motion in insert mode: <C-f> = next word (like w), <C-d> = previous
" word (like b). <C-o> runs one normal-mode command and returns to insert.
" (Note: this overrides insert-mode <C-d> dedent; use <C-t>/<BS> to adjust indent.)
inoremap <C-f> <C-o>w
inoremap <C-d> <C-o>b
" Skip quickfix buffer when switching
function! SwitchBuffer(direction)
  " Never cycle buffers OUT of a special window -- the :Git tab, coc's trees, help,
  " terminals. Those windows exist to show one thing, and cycling replaces what they
  " show: fugitive's status buffer is buflisted, so :bnext lands on it and walks off
  " it, and since it is bufhidden=delete leaving it destroys it outright, so the tab
  " you opened for :Git ends up holding an ordinary file.
  " 'winfixbuf' is the option that pins a buffer to a window, but it arrived in patch
  " 9.1.0147 and this Vim is 9.1.0113 (exists('+winfixbuf') == 0), so the guard has
  " to live here instead.
  if &buftype !=# ''
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

" Tab pages. `gt`/`gT` would be the native keys, but gt is taken by coc
" (`nmap gt <Plug>(coc-type-definition)` in 50-coc.vim), so tab-next has no key.
" These take over vim-unimpaired's ]t/[t (:tnext/:tprevious, ctags navigation) --
" unimpaired's s:Map() skips any lhs that is already mapped, and vimrc.d is sourced
" before plugin/ files, so defining them here wins cleanly with no <Plug> juggling.
" The displaced tag maps are still on ]<C-T>/[<C-T> (:ptnext/:ptprevious), and
" :tnext/:tprevious remain as commands; with coc and semcode doing the symbol
" lookups here, the ctags jumplist was not in use.
" NOTE: this diverges from nvim, where ]t/[t are still unimpaired.nvim's tag maps
" and there is no tab-switching key at all (<Tab> is bnext, same as here).
" The count is applied by hand rather than with :tabnext. A bare `:3tabnext` means
" "go to tab 3", not "3 tabs forward", and the relative `:tabnext +3` form does NOT
" wrap -- it fails at the last tab, so ]t was a no-op there instead of returning to
" the first. Modulo wraps in both directions and for counts larger than the tab count.
function! s:TabGo(delta) abort
  let l:total = tabpagenr('$')
  if l:total > 1
    execute ((tabpagenr() - 1 + a:delta) % l:total + l:total) % l:total + 1 . 'tabnext'
  endif
endfunction
nnoremap <silent> ]t :<C-U>call <SID>TabGo(v:count1)<CR>
nnoremap <silent> [t :<C-U>call <SID>TabGo(-v:count1)<CR>

" Window resizing. Same keys and same +-2 step as the nvim side, where these are
" LazyVim defaults (lazyvim/config/keymaps.lua:20-23). nvim ALSO has <A-h/j/k/l>
" via tmux.nvim, but Alt is unusable in this terminal Vim -- see the note at
" 50-coc.vim:510: no-GUI build under tmux, and :help map-alt-keys explains why
" Vim cannot tell <A-x> from <Esc>x reliably.
" Ctrl+arrow is safe here: both screen-256color and tmux-256color deliver
" CSI 1;5 A/B/D/C intact, verified by feeding the raw sequences to Vim, and all
" four are unmapped in this config. They also stay clear of <C-h/j/k/l>, which
" vim-tmux-navigator owns for *moving* between splits.
" A count multiplies the step (5<C-Up> = 10 lines); bare presses are exactly nvim's.
" NB: unlike nvim's <A-hjkl>, these resize Vim splits only -- they do not spill
" over into resizing the surrounding tmux pane.
nnoremap <silent> <C-Up>    :<C-U>execute 'resize +'          . (v:count1 * 2)<CR>
nnoremap <silent> <C-Down>  :<C-U>execute 'resize -'          . (v:count1 * 2)<CR>
nnoremap <silent> <C-Left>  :<C-U>execute 'vertical resize -' . (v:count1 * 2)<CR>
nnoremap <silent> <C-Right> :<C-U>execute 'vertical resize +' . (v:count1 * 2)<CR>
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

