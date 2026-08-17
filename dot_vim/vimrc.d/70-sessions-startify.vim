" 70-sessions-startify.vim -- sessions (startify) and the start screen.

" ---- sessions ----
" One file per project in a central dir, named from the cwd with '-' separators.
" NOT '%': :SLoad doesn't escape it, and such a session silently restores nothing.
let g:startify_session_dir = expand('$HOME/.local/state/vim/sessions')
call mkdir(g:startify_session_dir, 'p')

" Vim's default includes 'options', which bloats the file and lets a stale session
" fight the current config. Mirrors the nvim list minus that.
set sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions

function! s:ProjectSessionName() abort
  let l:name = substitute(getcwd()[1:], '[\\/:]', '-', 'g')
  return empty(l:name) ? 'root' : l:name
endfunction

" :Session save/overwrite this project's session; persistence then keeps it current.
command! -bar Session
            \ execute 'SSave! ' . fnameescape(<SID>ProjectSessionName())

" :SessionLoad restore it if present.
command! -bar SessionLoad
            \ execute filereadable(g:startify_session_dir . '/' . <SID>ProjectSessionName())
            \   ? 'SLoad ' . fnameescape(<SID>ProjectSessionName())
            \   : 'echo "No saved session for this project"'

" Rewrite on exit once a session is active. VimLeavePre only -- a SIGKILL loses
" everything since load.
let g:startify_session_persistence = 1
" Wipe buffers before restoring, so projects don't merge.
let g:startify_session_delete_buffers = 1

" Keep the start screen out of sessions. startify only avoids this when an
" alternate buffer exists, so saving straight off the start screen serialises
" filetype=startify and breaks the next load with E121 on g:startify_header.
function! s:WipeStartifyBuffers() abort
  for l:b in range(1, bufnr('$'))
    if bufexists(l:b) && getbufvar(l:b, '&filetype') ==# 'startify'
      execute 'silent! bwipeout!' l:b
    endif
  endfor
endfunction
" expand('<SID>'): startify runs these via bare :execute, where <SID> won't resolve.
let g:startify_session_before_save = ['call ' . expand('<SID>') . 'WipeStartifyBuffers()']

" Rescues sessions written before the above; the syntax file only takes len().
if !exists('g:startify_header')
  let g:startify_header = []
endif

" Auto-load this project's session when Vim starts bare, so :Session is a one-off.
" g:startify_session_autoload can't do it: that only sources ./Session.vim.
" Runs before startify's VimEnter, which then skips its start screen by itself.
" Set g:vimrc_session_autoload = 0 to load by hand instead.
function! s:SessionAutoload() abort
  " argc(): `vim foo.c` asked for something specific. v:this_session: `vim -S`.
  if !get(g:, 'vimrc_session_autoload', 1) || argc() || !empty(v:this_session)
    return
  endif
  " startify's own "still the empty scratch buffer" test; leaves `vim -` alone.
  if line('$') != 1 || !empty(getline(1)) || !empty(bufname('%'))
    return
  endif
  let l:name = s:ProjectSessionName()
  if filereadable(g:startify_session_dir . '/' . l:name)
    execute 'SLoad ' . fnameescape(l:name)
  endif
endfunction

augroup vimrc_sessions
  autocmd!
  autocmd VimEnter * ++once call s:SessionAutoload()
augroup END

" ---- start screen ----
" 'w' saves because startify, unlike obsession, only writes on :Session and exit.
let g:startify_commands = [
            \ {'g': ['Git status', 'Git']},
            \ {'f': ['Files', 'GFiles ${PWD}']},
            \ {'p': ['Load this project''s session', 'SessionLoad']},
            \ {'w': ['Save this project''s session', 'Session']},
            \ {'s': ['Edit vim config', 'Vimrc']},
            \ ]
" 's' is :Vimrc, not $MYVIMRC -- that is only the loader now.
let g:startify_lists = [
            \ { 'type': 'sessions',  'header': ['   Sessions']        },
            \ { 'type': 'dir',       'header': ['   Recent here']     },
            \ { 'type': 'commands',  'header': ['   Commands']        },
            \ ]
" 'dir' not 'files': 'files' is the global MRU and fills up with other projects.
" Header is static on purpose -- it is evaluated once, so getcwd() would go stale.
let g:startify_session_sort = 1
let g:startify_session_number = 8
let g:startify_change_to_dir = 0
" let g:startify_custom_header = g:ascii + startify#fortune#boxed()
let g:startify_files_number = 6
