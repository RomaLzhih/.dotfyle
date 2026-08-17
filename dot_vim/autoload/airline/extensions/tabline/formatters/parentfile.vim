" airline tabline formatter: <filetype icon> parent/file
" Selected by g:airline#extensions#tabline#formatter in 30-plugin-config.vim.
" Must live at this path -- airline resolves formatters by autoload name.
" The icon is prepended here rather than left to vim-devicons, whose wrapper
" appends it after the name; hence g:webdevicons_enable_airline_tabline = 0.

function! s:Icon(name) abort
  " plugin/ files load after vimrc.d and the tabline can be built during startup.
  return exists('*WebDevIconsGetFileTypeSymbol')
        \ ? WebDevIconsGetFileTypeSymbol(a:name) . ' '
        \ : ''
endfunction

function! airline#extensions#tabline#formatters#parentfile#format(bufnr, buffers) abort
  let l:name = bufname(a:bufnr)

  if empty(l:name)
    return airline#extensions#tabline#formatters#default#wrap_name(a:bufnr, '[No Name]')
  endif

  " Terminals have no parent worth showing; don't fnamemodify a term:// URL.
  if getbufvar(a:bufnr, '&buftype') ==# 'terminal' || l:name =~# '^term://'
    return airline#extensions#tabline#formatters#default#wrap_name(
          \ a:bufnr, s:Icon(l:name) . fnamemodify(l:name, ':t'))
  endif

  " ':p:h:t' is the parent's last component (/a/b/c.txt -> 'b'), empty at the
  " filesystem root where the tail alone is the whole answer.
  let l:tail   = fnamemodify(l:name, ':t')
  let l:parent = fnamemodify(l:name, ':p:h:t')
  let l:label  = empty(l:parent) ? l:tail : l:parent . '/' . l:tail

  " wrap_name() is airline's: it adds the modified marker and buffer_nr_show.
  return airline#extensions#tabline#formatters#default#wrap_name(
        \ a:bufnr, s:Icon(l:name) . l:label)
endfunction
