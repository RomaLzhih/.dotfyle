" 90-config-edit.vim -- reach the config now that ~/.vimrc is only a loader.
" :Vimrc [name] pick a config file (fzf) / :Vimrc! the loader / :VimrcGrep pat
" <leader>ve = :Vimrc, <leader>vg = :VimrcGrep. Sourced late: needs mapleader + fzf.

let s:vimrc_dir = expand('~/.vim/vimrc.d')

" Guarded, or `:source $MYVIMRC` appends a duplicate 'path' entry every time.
if stridx(&path, s:vimrc_dir) < 0
  execute 'set path+=' . fnameescape(s:vimrc_dir)
endif

function! s:VimrcFiles() abort
  return sort(glob(s:vimrc_dir . '/*.vim', 0, 1))
endfunction

" Short completion names: 50-coc.vim -> coc
function! s:VimrcComplete(lead, cmdline, pos) abort
  let l:names = map(s:VimrcFiles(), 'substitute(fnamemodify(v:val, ":t"), ''^\d\+-\|\.vim$'', "", "g")')
  return filter(l:names, 'v:val =~? a:lead')
endfunction

function! s:VimrcEdit(arg, bang) abort
  if a:bang
    " $MYVIMRC is unset under `vim -u`, so fall back to the real path.
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

" vimgrep not fzf: feeds the quickfix list, which is already configured.
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
