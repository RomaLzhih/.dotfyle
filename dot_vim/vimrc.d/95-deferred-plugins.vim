" 95-deferred-plugins.vim -- load {'on': []} plugins once Vim is idle (~16ms).
" Only plugins whose plugin/ file is pure maps/commands; never one used from
" -c/+cmd. See ~/.vim/CLAUDE.md.

let g:deferred_plugins = ['vim-unimpaired', 'vim-easymotion', 'vim-visual-multi']

function! s:LoadDeferredPlugins() abort
  if exists('g:plugs')
    call plug#load(filter(copy(g:deferred_plugins), 'has_key(g:plugs, v:val)'))
  endif
endfunction

augroup DeferredPlugins
  autocmd!
  if exists('##SafeState')
    autocmd SafeState * ++once call s:LoadDeferredPlugins()
  else
    autocmd VimEnter * ++once call timer_start(0, {-> s:LoadDeferredPlugins()})
  endif
  " Type-ahead / `vim -s`: load before pending keys run. getchar(1) only peeks.
  autocmd VimEnter * ++once if getchar(1) isnot 0 | call s:LoadDeferredPlugins() | endif
augroup END
