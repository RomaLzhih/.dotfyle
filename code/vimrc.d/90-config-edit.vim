" ============================================================================
" 90-config-edit.vim
" ----------------------------------------------------------------------------
" Getting at the config now that ~/.vimrc is only a loader, so `:e $MYVIMRC`
" no longer shows the settings themselves:
"
"   :Vimrc              fuzzy-pick a config file (fzf), or list them if no fzf
"   :Vimrc coc          jump straight to 50-coc.vim -- <Tab> completes the names
"   :VimrcGrep pattern  search every config file; hits land in the quickfix list
"   :Vimrc!             open ~/.vimrc itself (the loader)
"   <leader>ve          = :Vimrc
"   <leader>vg          = :VimrcGrep
"
" `gf` also works on the filenames listed in ~/.vimrc, because 'path' below
" includes the config directory.
"
" Sourced last so mapleader (20-) and fzf (00-) are already in place.
" Script-local (s:) items are file-scoped: keep every s: function together with
" its callers and <SID> mappings in this file.
" ============================================================================

let s:vimrc_dir = expand('~/.vim/vimrc.d')

" Guarded: a bare `set path+=` would append a duplicate entry on every
" `:source $MYVIMRC`.
if stridx(&path, s:vimrc_dir) < 0
  execute 'set path+=' . fnameescape(s:vimrc_dir)
endif

function! s:VimrcFiles() abort
  return sort(glob(s:vimrc_dir . '/*.vim', 0, 1))
endfunction

" Short, memorable names for completion: 50-coc.vim -> coc
function! s:VimrcComplete(lead, cmdline, pos) abort
  let l:names = map(s:VimrcFiles(), 'substitute(fnamemodify(v:val, ":t"), ''^\d\+-\|\.vim$'', "", "g")')
  return filter(l:names, 'v:val =~? a:lead')
endfunction

function! s:VimrcEdit(arg, bang) abort
  if a:bang
    " $MYVIMRC is unset when vim is started with -u, so fall back to the real path.
    execute 'edit ' . fnameescape(empty($MYVIMRC) ? expand('~/.vimrc') : expand($MYVIMRC))
    return
  endif
  if empty(a:arg)
    if exists(':Files') == 2
      execute 'Files ' . s:vimrc_dir
    else
      execute 'edit ' . fnameescape(s:vimrc_dir)
    endif
    return
  endif
  let l:hits = filter(s:VimrcFiles(), 'fnamemodify(v:val, ":t") =~? a:arg')
  if empty(l:hits)
    echohl WarningMsg | echomsg 'No config file matching: ' . a:arg | echohl None
    return
  endif
  execute 'edit ' . fnameescape(l:hits[0])
endfunction

" vimgrep rather than fzf here: it feeds the quickfix list, which is already set
" up (absolute numbers, no wrap, q to close) and needs no external tool.
function! s:VimrcGrep(pat) abort
  execute 'noautocmd vimgrep /' . escape(a:pat, '/') . '/j ' . fnameescape(s:vimrc_dir) . '/*.vim'
  if empty(getqflist())
    echohl WarningMsg | echomsg 'No match in config: ' . a:pat | echohl None
  else
    copen
  endif
endfunction

command! -nargs=? -bang -complete=customlist,<SID>VimrcComplete Vimrc
      \ call s:VimrcEdit(<q-args>, <bang>0)
command! -nargs=+ VimrcGrep call s:VimrcGrep(<q-args>)

nnoremap <silent> <leader>ve :Vimrc<CR>
nnoremap <leader>vg :VimrcGrep<Space>
