" 50-coc.vim -- coc.nvim (completion, diagnostics, goto), the peek-definition
" popup, and vim-signify's git/Sapling signs.

set nobackup
set nowritebackup
set cmdheight=1
set updatetime=300
set shortmess+=c
if has("nvim-0.5.0") || has("patch-8.1.1564")
    " No signcolumn=yes:N in this build, so one always-on column; VCS signs win
    " the slot via g:signify_priority below.
    set signcolumn=yes
else
    set signcolumn=yes
endif

" ---- vim-signify: VCS signs from the real diff (replaces coc-git) ----
" 'hg' drives Sapling working copies like fbsource, so signs follow `sl diff`.
" g:signify_vcs_list is dead upstream; g:signify_skip is the supported knob, and
" without it the backend list is every installed VCS, not the two intended.
let g:signify_skip = { 'vcs': { 'allow': ['git', 'hg'] } }
" Beat vim-signature/vim-bookmarks (priority 10) to the single signcolumn slot.
let g:signify_priority = 11

" git/hg emit no diff for untracked files, so a wrapper renders them all-added,
" matching coc-git. See ~/.vim/bin/sy-diff.sh
let g:signify_vcs_cmds = {
      \ 'git': expand('~/.vim/bin/sy-diff.sh') . ' git %f',
      \ 'hg':  expand('~/.vim/bin/sy-diff.sh') . ' hg %f',
      \ }

" coc-git's icons.
let g:signify_sign_add               = '+'
let g:signify_sign_change            = '~'
let g:signify_sign_delete            = '_'
let g:signify_sign_delete_first_line = '‾'
let g:signify_sign_change_delete     = '≃'
let g:signify_sign_show_count        = 0   " no trailing hunk count, like coc-git

" Drop signify's CursorHoldI refresh, keep the normal-mode one. On a &modified
" buffer that refresh writes the WHOLE buffer synchronously before diffing --
" 1.6ms on fork.c, 6.8ms on verifier.c -- every 300ms pause while typing.
" Trade-off: signs for lines you are typing land after <Esc>, or on write.
augroup vimrc_signify
  autocmd!
  autocmd User SignifyAutocmds autocmd! signify CursorHoldI
augroup END

" Dark icon on an accent background; re-applied on :colorscheme.
function! s:SignifyGitSignStyle() abort
  highlight SignifySignAdd             guifg=#282828 guibg=#b8bb26 ctermfg=235 ctermbg=142
  highlight SignifySignChange          guifg=#282828 guibg=#8ec07c ctermfg=235 ctermbg=108
  highlight SignifySignChangeDelete    guifg=#282828 guibg=#d3869b ctermfg=235 ctermbg=175
  highlight SignifySignDelete          guifg=#282828 guibg=#fb4934 ctermfg=235 ctermbg=167
  highlight SignifySignDeleteFirstLine guifg=#282828 guibg=#fb4934 ctermfg=235 ctermbg=167
endfunction
augroup SignifyGitSignStyle
  autocmd!
  autocmd ColorScheme * call s:SignifyGitSignStyle()
augroup END
call s:SignifyGitSignStyle()

" ---- completion ----
inoremap <silent><expr> <C-x> coc#pum#visible() ? coc#pum#cancel() : "\<C-x>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
let g:coc_snippet_prev = '<C-p>'
let g:coc_snippet_next = '<C-n>'
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#_select_confirm() : "\<CR>"

" ---- navigation ----
" ]d/[d = git hunks (signify); ]e/[e = diagnostics.
nmap <silent> ]d <plug>(signify-next-hunk)
nmap <silent> [d <plug>(signify-prev-hunk)
nmap <silent> [e <Plug>(coc-diagnostic-prev)
nmap <silent> ]e <Plug>(coc-diagnostic-next)

" Own gd: coc#util#jump()'s fast path does a name-based `:b`, which returns -1 for
" a file already open under a symlinked name (common in fbsource), so coc's gd
" fails to jump there. This uses definitions + :edit and records the jumplist.
function! s:GotoDefinition() abort
  try
    let l:defs = CocAction('definitions')
  catch
    return
  endtry
  " 0 or multiple results: defer to coc's own picker/message.
  if type(l:defs) != type([]) || len(l:defs) != 1
    call CocActionAsync('jumpDefinition')
    return
  endif
  let l:loc = l:defs[0]
  let l:uri = get(l:loc, 'uri', get(l:loc, 'targetUri', ''))
  let l:range = get(l:loc, 'range', get(l:loc, 'targetRange', {}))
  if empty(l:uri) || empty(l:range)
    call CocActionAsync('jumpDefinition')
    return
  endif
  let l:file = substitute(l:uri, '^file://', '', '')
  let l:file = substitute(l:file, '%\(\x\x\)', '\=nr2char(str2nr(submatch(1), 16))', 'g')
  let l:line = get(l:range.start, 'line', 0) + 1
  let l:char = get(l:range.start, 'character', 0)
  if fnamemodify(l:file, ':p') ==# expand('%:p')
    execute 'normal! ' . l:line . 'G'
  else
    execute 'edit +' . l:line . ' ' . fnameescape(l:file)
  endif
  let l:cur = getline(l:line)
  let l:col = l:char + 1
  if !empty(l:cur)
    try | let l:col = coc#string#byte_index(l:cur, l:char) + 1 | catch | endtry
  endif
  call cursor(l:line, l:col)
  normal! zz
endfunction
nnoremap <silent> gd :call <SID>GotoDefinition()<CR>
nnoremap <silent><nowait> <leader>pd  :call <SID>PeekDefinition()<CR>
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" ---- peek definition ----
" Read-only popup: j/k, <C-d>/<C-u>, gg/G scroll; o jumps; q/<Esc> closes.
" The current-line marker is a matchaddpos(), not the popup's 'cursorline': that
" uses PmenuSel (fg+bg) and would overwrite syntax/semantic colours, whereas a
" match layers UNDER syntax so only the background changes.
" The colour is derived from the theme -- first candidate with a background that
" clashes with neither the popup body (Normal) nor its scrollbar.
function! s:PeekHl() abort
  " 'Normal' because popup_create() below passes highlight=Normal, so the popup
  " reads as an ordinary buffer rather than a Pmenu slab. CursorLine then wins,
  " which is what a real buffer shows. PmenuThumb/Sbar stay: the scrollbar uses them.
  let l:avoid = []
  for l:g in ['Normal', 'PmenuThumb', 'PmenuSbar']
    let l:aid = synIDtrans(hlID(l:g))
    if l:aid
      call add(l:avoid, [synIDattr(l:aid, 'bg#', 'gui'), synIDattr(l:aid, 'bg', 'cterm')])
    endif
  endfor
  let l:gui = ''
  let l:cterm = ''
  for l:cand in ['CursorLine', 'Visual', 'PmenuSel', 'ColorColumn', 'CursorColumn', 'Search']
    let l:id = synIDtrans(hlID(l:cand))
    if l:id == 0
      continue
    endif
    let l:bg = synIDattr(l:id, 'bg#', 'gui')
    let l:bc = synIDattr(l:id, 'bg', 'cterm')
    if empty(l:bg) && empty(l:bc)
      continue
    endif
    let l:clash = 0
    for [l:ag, l:ac] in l:avoid
      if (!empty(l:bg) && l:bg ==? l:ag) || (empty(l:bg) && !empty(l:bc) && l:bc ==? l:ac)
        let l:clash = 1
        break
      endif
    endfor
    if !l:clash
      let l:gui = l:bg
      let l:cterm = l:bc
      break
    endif
  endfor
  if empty(l:gui) && empty(l:cterm)
    " No distinct background in this theme -- reverse works everywhere.
    highlight PeekCursorLine gui=reverse cterm=reverse
    return
  endif
  execute 'hi! PeekCursorLine guifg=NONE ctermfg=NONE gui=NONE cterm=NONE'
        \ . (empty(l:gui) ? '' : ' guibg=' . l:gui)
        \ . (empty(l:cterm) ? '' : ' ctermbg=' . l:cterm)
endfunction
augroup PeekCursorLineHl
  autocmd!
  autocmd ColorScheme * call s:PeekHl()
augroup END
call s:PeekHl()

" Only re-mark when the line actually changed; the redundant clearmatches() and
" redraw on every keypress is the scrolling lag over a remote terminal.
function! s:PeekMark(winid) abort
  let l:cur = line('.', a:winid)
  if get(s:, 'peek_marked_line', -1) ==# l:cur
    return
  endif
  let s:peek_marked_line = l:cur
  call win_execute(a:winid, 'silent! call clearmatches() | call matchaddpos("PeekCursorLine", [' . l:cur . '])')
endfunction

function! s:PeekFilter(winid, key) abort
  if a:key ==# 'q' || a:key ==# "\<Esc>"
    call popup_close(a:winid)
    return 1
  elseif a:key ==# 'o'
    call popup_close(a:winid)
    if get(s:, 'peek_file', '') !=# ''
      if s:peek_file !=# expand('%:p') && filereadable(s:peek_file)
        execute 'edit ' . fnameescape(s:peek_file)
      endif
      call cursor(s:peek_line, s:peek_col)
      normal! zz
    endif
    return 1
  elseif a:key ==# 'j' || a:key ==# "\<Down>"
    call win_execute(a:winid, "normal! \<C-e>")
  elseif a:key ==# 'k' || a:key ==# "\<Up>"
    call win_execute(a:winid, "normal! \<C-y>")
  elseif a:key ==# "\<C-d>" || a:key ==# "\<C-f>"
    call win_execute(a:winid, "normal! \<C-d>")
  elseif a:key ==# "\<C-u>" || a:key ==# "\<C-b>"
    call win_execute(a:winid, "normal! \<C-u>")
  elseif a:key ==# 'g'
    call win_execute(a:winid, 'normal! gg')
  elseif a:key ==# 'G'
    call win_execute(a:winid, 'normal! G')
  else
    " Swallow everything else so a stray key can't dismiss the float.
    return 1
  endif
  call s:PeekMark(a:winid)
  return 1
endfunction

function! s:PeekDefinition() abort
  try
    let l:defs = CocAction('definitions')
  catch
    echohl WarningMsg | echom 'Peek: coc not ready' | echohl None
    return
  endtry
  if type(l:defs) != type([]) || empty(l:defs)
    echohl WarningMsg | echom 'Peek: no definition found' | echohl None
    return
  endif
  let l:loc = l:defs[0]
  let l:uri = get(l:loc, 'uri', get(l:loc, 'targetUri', ''))
  let l:range = get(l:loc, 'range', get(l:loc, 'targetRange', {}))
  if empty(l:uri) || empty(l:range)
    echohl WarningMsg | echom 'Peek: malformed location' | echohl None
    return
  endif
  let l:file = substitute(l:uri, '^file://', '', '')
  let l:file = substitute(l:file, '%\(\x\x\)', '\=nr2char(str2nr(submatch(1), 16))', 'g')
  " Live buffer if open (unsaved edits), else disk.
  let l:bnr = bufnr(l:file)
  if l:bnr > 0 && bufloaded(l:bnr)
    let l:all = getbufline(l:bnr, 1, '$')
  elseif filereadable(l:file)
    let l:all = readfile(l:file)
  else
    echohl WarningMsg | echom 'Peek: cannot read ' . l:file | echohl None
    return
  endif
  " A bounded window, not the whole file: a large buffer positioned deep re-parses
  " syntax on the first jump into an unhighlighted region, which is the visible lag.
  let l:start = get(l:range.start, 'line', 0)
  let l:before = 200
  let l:after  = 500
  let l:winstart = max([l:start - l:before, 0])
  let l:winend   = min([l:start + l:after, len(l:all) - 1])
  let l:content  = l:all[l:winstart : l:winend]
  let l:def_in_popup = l:start - l:winstart + 1
  let l:ft = &filetype
  " Remembered so the popup's `o` can jump there.
  let s:peek_file = l:file
  let s:peek_line = l:start + 1
  let s:peek_col  = get(l:range.start, 'character', 0) + 1
  " 80%/60% of the current window, centred; border+padding cost 4 cols / 2 rows.
  let l:wpos = win_screenpos(0)
  let l:pw   = winwidth(0)
  let l:ph   = winheight(0)
  let l:tw   = float2nr(l:pw * 0.80)
  let l:th   = float2nr(l:ph * 0.60)
  let l:cw   = max([40, l:tw - 4])
  let l:ch   = max([3,  l:th - 2])
  let l:winid = popup_create(l:content, {
        \ 'line': l:wpos[0] + (l:ph - l:th) / 2,
        \ 'col': l:wpos[1] + (l:pw - l:tw) / 2,
        \ 'title': ' ' . fnamemodify(l:file, ':t') . ':' . (l:start + 1) . '  (o open, q quit) ',
        \ 'border': [],
        \ 'padding': [0, 1, 0, 1],
        \ 'highlight': 'Normal',
        \ 'borderhighlight': ['Comment'],
        \ 'minheight': 3,
        \ 'maxheight': l:ch,
        \ 'minwidth': l:cw,
        \ 'maxwidth': l:cw,
        \ 'scrollbar': 1,
        \ 'mapping': 0,
        \ 'filtermode': 'n',
        \ 'filter': function('s:PeekFilter'),
        \ })
  if l:winid > 0
    " Show a few lines of context above the definition rather than pinning it to
    " the top; clamped for definitions near the start of the file.
    let l:above = min([get(g:, 'peek_context_above', 3), l:def_in_popup - 1])
    call win_execute(l:winid, 'setlocal scrolloff=0')
    call win_execute(l:winid, printf('call winrestview({"lnum": %d, "col": 0, "topline": %d})',
          \ l:def_in_popup, l:def_in_popup - l:above))
    if !empty(l:ft)
      call win_execute(l:winid, 'setlocal filetype=' . l:ft)
    endif
    let s:peek_marked_line = -1
    call s:PeekMark(l:winid)
  endif
endfunction

" ---- documentation, actions, text objects ----
nnoremap <silent> K :call <SID>show_documentation()<CR>
let g:coc_global_extensions = ['coc-clangd', 'coc-sh', 'coc-diagnostic', 'coc-highlight', 'coc-rust-analyzer', 'coc-yank']

function! s:show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
    elseif (coc#rpc#ready())
        call CocActionAsync('doHover')
    else
        execute '!' . &keywordprg . " " . expand('<cword>')
    endif
endfunction

augroup vimrc_coc_extra
  autocmd!
  " Skipped on big buffers (b:big_file from 10-options.vim). The dispatch is async
  " and ~0.006ms; what this avoids is the server lookup and highlight application.
  autocmd CursorHold * if !get(b:, 'big_file', 0) | silent call CocActionAsync('highlight') | endif
augroup END

nmap <leader>rn <Plug>(coc-rename)
nmap <leader>il :CocCommand document.toggleInlayHint <CR>
nmap <leader>ic :call CocAction('showIncomingCalls') <CR>
nmap <leader>oc :call CocAction('showOutgoingCalls') <CR>
" NOTE: no `autocmd!` -- it would wipe the CursorHold entry above.
augroup vimrc_coc_extra
  autocmd FileType coctree nnoremap <silent><buffer> q :close<CR>
  " One symbol per line in a narrow split, so wrapping breaks the tree indent.
  " Here rather than 10-'s nowrap list because coc's hover windows are prose.
  autocmd FileType coctree setlocal nowrap
augroup END

augroup mygroup
    autocmd!
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

nmap <leader>ca  <Plug>(coc-codeaction)
nmap <leader>qf  <Plug>(coc-fix-current)

" Function/class text objects. Needs documentSymbol support from the server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)
xmap . <Plug>(coc-range-select)
omap . <Plug>(coc-range-select)

command! -nargs=0 Format :call CocAction('format')
" <leader>fm matches nvim's conform binding; it displaced fzf's :Marks, which
" moved to <leader>fk (50- is sourced after 30-, so both would have collided).
" Formatting goes through the LSP, so clangd picks up the repo's .clang-format.
nnoremap <silent> <leader>fm :Format<CR>
xmap     <silent> <leader>fm <Plug>(coc-format-selected)
command! -nargs=0 Inspect :CocCommand semanticTokens.inspect
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" ---- CocList ----
nnoremap <silent><nowait> <space>sbd  :<C-u>CocList diagnostics<cr>
nnoremap <silent><nowait> <Leader>fu  :<C-u>CocList outline<cr>
" Yank ring (nvim's yanky.nvim equivalent), persists across Vim instances.
" vim-peekaboo still shows the live registers; this is the history they overwrote.
nnoremap <silent><nowait> <Leader>yk  :<C-u>CocList yank<cr>

" Persistent outline sidebar (nvim's outline.nvim equivalent).
" Toggled by checking for the window: the docs say hideOutline throws when there
" is nothing to close, but here it returns normally, so a try/catch never shows.
" Geometry/sort live in ~/.vim/coc-settings.json.
" Caveat: the call trees share the 'coctree' filetype, so with one of those open
" this hides that instead. On <leader>ot because Alt is unusable in terminal Vim.
function! s:HasCocTree() abort
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'coctree'
      return 1
    endif
  endfor
  return 0
endfunction

function! s:ToggleOutline() abort
  if s:HasCocTree()
    call CocAction('hideOutline')
  else
    call CocActionAsync('showOutline')
  endif
endfunction
nnoremap <silent> <leader>ot :call <SID>ToggleOutline()<CR>
