" ============================================================================
" 70-sessions-startify.vim
" ----------------------------------------------------------------------------
" Session handling (startify) and the startify start screen.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" -----------------------------SESSIONS-----------------------------------
" startify owns sessions now (vim-obsession was dropped). One file per project,
" in one central folder rather than a Session.vim in every project dir.
"
" The name is derived from the cwd, so :Session always rewrites the SAME file for
" a given project instead of accumulating one per save. Path separators become
" '-', NOT '%': startify's :SLoad does not escape '%' before sourcing, so a
" '%'-named session lists on the start screen but silently restores only the
" current buffer. (That is why the old obsession-era names can't just be reused.)
let g:startify_session_dir = expand('$HOME/.local/state/vim/sessions')
call mkdir(g:startify_session_dir, 'p')

" What goes IN a session. Vim's default includes 'options', which serialises every
" global/local option and mapping -- that bloats the file and makes a stale session
" fight the current config. This is the nvim config's list (lua/config/autocmds.lua),
" minus that.
set sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions

function! s:ProjectSessionName() abort
  let l:name = substitute(getcwd()[1:], '[\\/:]', '-', 'g')
  return empty(l:name) ? 'root' : l:name
endfunction

" :Session      save/overwrite this project's session (the ! skips the prompt).
"               After this, startify_session_persistence keeps it up to date on exit.
command! -bar Session
            \ execute 'SSave! ' . fnameescape(<SID>ProjectSessionName())

" :SessionLoad  restore this project's saved session if present
command! -bar SessionLoad
            \ execute filereadable(g:startify_session_dir . '/' . <SID>ProjectSessionName())
            \   ? 'SLoad ' . fnameescape(<SID>ProjectSessionName())
            \   : 'echo "No saved session for this project"'

" Once a session is active (loaded, or just saved with :Session), update it on
" exit. Without this you would have to remember to re-run :Session before quitting.
" NOTE: this only writes at VimLeavePre -- unlike vim-obsession, which rewrote
" continuously, a SIGKILL loses everything since the session was loaded.
let g:startify_session_persistence = 1
" Wipe the current buffers before restoring, so loading a session doesn't merge
" the previous project's buffers into it.
let g:startify_session_delete_buffers = 1

" Auto-load this project's session when Vim is started bare in a directory that
" has one, so `:Session` only ever has to be run once per project.
" g:startify_session_autoload is NOT the way to do this: it only sources a literal
" Session.vim in the cwd (startify plugin/startify.vim:38), whereas these sessions
" live in one central folder under cwd-derived names.
" Runs before startify's own VimEnter -- this file is sourced from the vimrc, its
" plugin/ file afterwards, and autocommands for an event fire in definition order.
" Startify then finds a real buffer loaded and skips its start screen on its own
" (its guard at plugin/startify.vim:37 requires a single empty unnamed line), so
" the two do not fight and the start screen still appears when there is no session.
" Set g:vimrc_session_autoload = 0 to go back to loading by hand with :SessionLoad.
function! s:SessionAutoload() abort
  " argc(): `vim foo.c` asked for something specific, don't override it.
  " v:this_session: already non-empty for `vim -S ...`, so don't load twice.
  if !get(g:, 'vimrc_session_autoload', 1) || argc() || !empty(v:this_session)
    return
  endif
  " Same "is this still the empty scratch buffer" test startify uses, so piped
  " input (vim -) or anything that already populated a buffer is left alone.
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

" -----------------------------STARTIFY-----------------------------------
" 'w' (save) is new since vim-obsession was dropped. Obsession tracked continuously
" once started, so the start screen only ever needed a "load" entry. startify only
" writes on :Session and then on exit (g:startify_session_persistence), so starting a
" session for a project is now an explicit act and needs to be reachable from here.
" 'w' matches the nvim config's <leader>ws (SessionSave).
let g:startify_commands = [
            \ {'g': ['Git status', 'Git']},
            \ {'f': ['Files', 'GFiles ${PWD}']},
            \ {'p': ['Load this project''s session', 'SessionLoad']},
            \ {'w': ['Save this project''s session', 'Session']},
            \ {'s': ['Edit vim config', 'Vimrc']},
            \ ]
" 's' runs :Vimrc (90-config-edit.vim), which fuzzy-picks among ~/.vim/vimrc.d/*.vim,
" rather than `e $MYVIMRC` -- since the config was split, $MYVIMRC is only the loader
" and contains none of the settings. :Vimrc! still opens the loader itself.
let g:startify_lists = [
            \ { 'type': 'sessions',  'header': ['   Sessions']        },
            \ { 'type': 'dir',       'header': ['   Recent here']     },
            \ { 'type': 'commands',  'header': ['   Commands']        },
            \ ]
" 'dir' rather than 'files': 'files' is the GLOBAL v:oldfiles MRU, so the start
" screen filled up with files from other projects. 'dir' filters that same MRU to
" the cwd and prints each entry relative to it (startify's s:show_dir ->
" s:display_by_path(getcwd(), ':.')). The header is deliberately static -- it is
" evaluated once when this list is assigned, so embedding getcwd() in it (as
" startify's own default does) would go stale after a :cd, even though the list
" itself re-filters on every redraw.
" Most recently used sessions first, and cap the list so the start screen stays short.
let g:startify_session_sort = 1
let g:startify_session_number = 8
let g:startify_change_to_dir = 0
" let g:startify_custom_header = g:ascii + startify#fortune#boxed()
let g:startify_files_number = 6


