" ============================================================================
" 95-deferred-plugins.vim
" ----------------------------------------------------------------------------
" Plugins registered with {'on': []} in 00-plugins.vim are inert until something
" calls plug#load(). Load them once Vim is idle, so their plugin/ files are off
" the startup path. Worth ~16ms here.
"
" MEASURED: SafeState fires at the very end of startup, well after this file is
" sourced. Anything that consumes input before then would see the maps missing,
" so there are two load paths:
"
"   VimEnter + getchar(1)  keys already typed ahead (shell type-ahead, or
"                          `vim -s script`). VimEnter runs before the typeahead
"                          is processed, so loading here removes that race.
"                          getchar(1) only PEEKS -- it does not eat the key.
"   SafeState              nothing pending -> defer; this is where the win is.
"
" NOT COVERED: `vim -c cmd` / `vim +cmd`. Those run before VimEnter, so a startup
" command that uses one of these plugins will fail. Never defer a plugin you
" invoke from -c/+cmd.
"
" ONLY list plugins whose plugin/ file is pure mappings/commands. A plugin whose
" plugin/ file registers a VimEnter autocmd must NOT go here -- VimEnter has
" already fired by the time SafeState runs. (That is why copilot is not listed:
" copilot/plugin/copilot.vim does `autocmd VimEnter * ... call copilot#Init()`,
" so deferring it would silently never start the language server.)
"
" Idempotent: the augroup is cleared on `:source $MYVIMRC` and plug#load()
" returns 0 for anything already loaded.
"
" Sourced last, so plug#end() (00-) has already populated g:plugs.
" Script-local (s:) items are file-scoped: keep every s: function together with
" its callers and <SID> mappings in this file.
" ============================================================================

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
  " Type-ahead / `vim -s`: load before the pending keys are processed.
  autocmd VimEnter * ++once if getchar(1) isnot 0 | call s:LoadDeferredPlugins() | endif
augroup END
