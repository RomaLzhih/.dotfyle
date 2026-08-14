" ============================================================================
" airline tabline formatter: <filetype icon> parent/file
" ----------------------------------------------------------------------------
" Selected by g:airline#extensions#tabline#formatter = 'parentfile' in
" ~/.vim/vimrc.d/30-plugin-config.vim. It has to live at this path: airline
" resolves formatters by autoload name, calling
" airline#extensions#tabline#formatters#{formatter}#format().
"
" The icon is prepended HERE rather than left to vim-devicons. Devicons wraps
" whatever formatter you choose (plugin/webdevicons.vim:604-609 stashes it in
" g:_webdevicons_airline_orig_formatter) and its wrapper appends the glyph AFTER
" the name. So g:webdevicons_enable_airline_tabline is set to 0 next to the
" formatter option -- otherwise devicons would substitute its own formatter for
" this one and the icon would land on the wrong side.
" ============================================================================

function! s:Icon(name) abort
  " Devicons is a normal (non-deferred) plugin, but plugin/ files load after
  " vimrc.d and the tabline can be built during startup, so don't assume it.
  return exists('*WebDevIconsGetFileTypeSymbol')
        \ ? WebDevIconsGetFileTypeSymbol(a:name) . ' '
        \ : ''
endfunction

function! airline#extensions#tabline#formatters#parentfile#format(bufnr, buffers) abort
  let l:name = bufname(a:bufnr)

  if empty(l:name)
    return airline#extensions#tabline#formatters#default#wrap_name(a:bufnr, '[No Name]')
  endif

  " Terminals have no meaningful parent directory; keep them recognisable
  " instead of running fnamemodify over a term:// URL.
  if getbufvar(a:bufnr, '&buftype') ==# 'terminal' || l:name =~# '^term://'
    return airline#extensions#tabline#formatters#default#wrap_name(
          \ a:bufnr, s:Icon(l:name) . fnamemodify(l:name, ':t'))
  endif

  " ':p:h:t' is the parent directory's own last component: /a/b/c.txt -> 'b'.
  " It comes back empty for a file at the filesystem root, where the tail alone
  " is the whole answer.
  let l:tail   = fnamemodify(l:name, ':t')
  let l:parent = fnamemodify(l:name, ':p:h:t')
  let l:label  = empty(l:parent) ? l:tail : l:parent . '/' . l:tail

  " wrap_name() is airline's own: it appends the modified marker and honours
  " g:airline#extensions#tabline#buffer_nr_show, so those keep working.
  return airline#extensions#tabline#formatters#default#wrap_name(
        \ a:bufnr, s:Icon(l:name) . l:label)
endfunction
