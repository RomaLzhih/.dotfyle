" ============================================================================
" 70-sessions-startify.vim
" ----------------------------------------------------------------------------
" vim-obsession session handling and the startify start screen.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" -----------------------------SESSIONS-----------------------------------
" Keep vim-obsession session files in one central folder instead of cluttering
" each project dir. One file per project (named after its path); change
" g:session_dir to relocate them.
let g:session_dir = expand('$HOME/.local/state/vim/sessions')
call mkdir(g:session_dir, 'p')

function! s:ProjectSessionFile() abort
    return g:session_dir . '/' . substitute(getcwd(), '[\\/:]', '%', 'g') . '.vim'
endfunction

" :Session[!]  start tracking into the central per-project file; when already
"              tracking, :Session pauses and :Session! deletes (obsession behaviour)
command! -bar -bang Session
            \ execute exists('g:this_obsession')
            \   ? 'Obsession<bang>'
            \   : 'Obsession<bang> ' . fnameescape(<SID>ProjectSessionFile())

" :SessionLoad  restore this project's saved session if present
command! -bar SessionLoad
            \ execute filereadable(<SID>ProjectSessionFile())
            \   ? 'source ' . fnameescape(<SID>ProjectSessionFile())
            \   : 'echo "No saved session for this project"'

" -----------------------------STARTIFY-----------------------------------
let g:startify_commands = [
            \ {'g': ['Git status', 'Git']},
            \ {'f': ['Files', 'GFiles ${PWD}']},
            \ {'p': ['Previous session', 'SessionLoad']},
            \ {'s': ['Edit .vimrc', 'e $MYVIMRC']},
            \ ]
let g:startify_lists = [
            \ { 'type': 'files',     'header': ['   Recent']            },
            \ { 'type': 'commands',  'header': ['   Commands']       },
            \ ]
let g:startify_change_to_dir = 0
" let g:startify_custom_header = g:ascii + startify#fortune#boxed()
let g:startify_files_number = 6


