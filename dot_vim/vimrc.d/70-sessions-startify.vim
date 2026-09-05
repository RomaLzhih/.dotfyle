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

" Optionally auto-load this project's session when Vim starts bare.
" OFF by default: a bare start shows the start screen, and `p` there (:SessionLoad)
" restores the session on request. Set g:vimrc_session_autoload = 1 to restore
" on entry instead; that runs before startify's VimEnter, which then skips its
" start screen by itself. g:startify_session_autoload can't do either: it only
" sources ./Session.vim.
function! s:SessionAutoload() abort
  " argc(): `vim foo.c` asked for something specific. v:this_session: `vim -S`.
  if !get(g:, 'vimrc_session_autoload', 0) || argc() || !empty(v:this_session)
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

" Save this project's session on exit even when one was never created by hand.
" startify's persistence only rewrites a session that is already ACTIVE: its
" s:on_vimleavepre() gates on filewritable(v:this_session), so the first
" :Session per project was always manual. Mirrors nvim, where LazyVim's
" persistence.nvim is lazy on BufReadPre and likewise only records a project
" once a real file has been opened there.
" Set g:vimrc_session_autosave = 0 to go back to manual-first.
function! s:SessionWorthSaving() abort
  let l:real = 0
  for l:b in getbufinfo({'buflisted': 1})
    if empty(l:b.name) || !empty(getbufvar(l:b.bufnr, '&buftype'))
      continue
    endif
    " Vim as git's editor: COMMIT_EDITMSG, MERGE_MSG and the rebase todo all sit
    " under .git/. Saving then would replace a good project session with a
    " one-file scratch -- `vim <file>` never autoloads, so v:this_session is
    " empty and nothing else would stop it. Every `git commit` would clobber it.
    if l:b.name =~# '/\.git/'
          \ || getbufvar(l:b.bufnr, '&filetype') =~# '^git\%(commit\|rebase\)$'
      return 0
    endif
    let l:real = 1
  endfor
  return l:real
endfunction

function! s:SessionAutosave() abort
  " A live session is startify's job; doing it here too would just write twice.
  if !get(g:, 'vimrc_session_autosave', 1) || !empty(v:this_session)
    return
  endif
  " Only a Vim that started bare owns this project's session, the same test
  " s:SessionAutoload() uses. `vim <file>` is a visit, not the project: letting
  " it write would replace a five-file session with whatever single file you
  " opened to glance at. Recorded at VimEnter because :args can change argc().
  if !get(s:, 'started_bare', 0)
    return
  endif
  " A session already exists and was NOT loaded this run (v:this_session is
  " empty here). Without autoload that is the normal case, and writing now would
  " replace the saved layout with whatever was opened since the start screen.
  " Replacing it on purpose is `w` on the start screen or :Session.
  if filereadable(g:startify_session_dir . '/' . s:ProjectSessionName())
    return
  endif
  if s:SessionWorthSaving()
    silent Session
  endif
endfunction

augroup vimrc_sessions
  autocmd!
  autocmd VimEnter * ++once let s:started_bare = argc() == 0
  autocmd VimEnter * ++once call s:SessionAutoload()
  autocmd VimLeavePre * call s:SessionAutosave()
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
