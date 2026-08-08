" ============================================================================
" 50-coc.vim
" ----------------------------------------------------------------------------
" coc.nvim: completion, diagnostics, go-to-definition, the
" peek-definition popup, and vim-signify's git/Sapling signs.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" ---------------------------------------COC---------------------------------------------
" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup
" Give more space for displaying messages.
set cmdheight=1
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300
" Don't pass messages to |ins-completion-menu|.
set shortmess+=c
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
    " This vim build doesn't support the signcolumn=yes:N (multi-width) syntax,
    " so keep a single always-on column and make VCS signs win the slot via
    " g:signify_priority (otherwise placing a mark/bookmark on a changed line
    " would hide that line's change sign).
    set signcolumn=yes
else
    set signcolumn=yes
endif

" --- vim-signify: VCS change signs from the real diff (replaces coc-git) ---
" 'git' covers dotfile repos; the 'hg' backend drives Sapling (sl) working
" copies like fbsource, so signs reflect `sl diff` -- not just session edits.
let g:signify_vcs_list = ['git', 'hg']
" Win the single signcolumn slot over vim-signature/vim-bookmarks (priority 10),
" mirroring the previous coc-git git.signPriority = 11.
let g:signify_priority = 11

" New/untracked files show no diff by default (git/hg diff emit nothing), so no
" signs appear. Route git+hg through a wrapper that renders an untracked file as
" all-added -- coc-git parity. See ~/.vim/bin/sy-diff.sh
let g:signify_vcs_cmds = {
      \ 'git': expand('~/.vim/bin/sy-diff.sh') . ' git %f',
      \ 'hg':  expand('~/.vim/bin/sy-diff.sh') . ' hg %f',
      \ }

" --- coc-git-style signs: coc-git's exact icons + a colored background block ---
let g:signify_sign_add               = '+'
let g:signify_sign_change            = '~'
let g:signify_sign_delete            = '_'
let g:signify_sign_delete_first_line = '‾'
let g:signify_sign_change_delete     = '≃'
let g:signify_sign_show_count        = 0   " no trailing hunk count, like coc-git

" Dark icon on an accent-colored background (gruvbox palette). Wrapped in a
" ColorScheme autocmd so it survives a :colorscheme reload.
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
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <C-x> coc#pum#visible() ? coc#pum#cancel() : "\<C-x>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
let g:coc_snippet_prev = '<C-p>'
let g:coc_snippet_next = '<C-n>'

" inoremap <silent><expr> <TAB>
"             \ coc#pum#visible() ? coc#pum#next(1):
"             \ exists('b:_copilot.suggestions') ? copilot#Accept("\<CR>") :
"             \ CheckBackSpace() ? "\<Tab>" :
"             \ coc#refresh()
" Use <c-space> to trigger completion.
" if has('nvim')
"     inoremap <silent><expr> <c-space> coc#refresh()
" else
" endif
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#_select_confirm() : "\<CR>"

" ]d / [d jump to the next / previous git change block (vim-signify hunk).
nmap <silent> ]d <plug>(signify-next-hunk)
nmap <silent> [d <plug>(signify-prev-hunk)
" Diagnostics moved to ]e / [e (was ]d / [d).
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [e <Plug>(coc-diagnostic-prev)
nmap <silent> ]e <Plug>(coc-diagnostic-next)
" GoTo code navigation.
" Robust go-to-definition. coc#util#jump() has an 'edit && bufloaded' fast-path
" that runs `:b bufnr(name)` -- a name-based lookup that returns -1 for a file
" already open under a different/symlinked name (common in fbsource), so coc's gd
" fails to jump to an already-open OTHER file (same-file still works). This uses
" CocAction('definitions') + :edit (the reliable path the peek popup uses) and
" records the jumplist so <C-o> returns.
function! s:GotoDefinition() abort
  try
    let l:defs = CocAction('definitions')
  catch
    return
  endtry
  " For 0 or multiple results, defer to coc (its picker / message).
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

" Peek definition in a floating window without jumping. Scroll with j/k,
" <C-d>/<C-u>, or gg/G; press o to jump to the location, q/<Esc> to close.
" (Vim popups are read-only; use a split/preview if you need to edit there.)
" bg-only current-line highlight for the peek popup. We do NOT use the popup's
" 'cursorline' option: that uses PmenuSel (fg+bg) and would overwrite the line's
" syntax/semantic-token colors. matchaddpos layers UNDER syntax, so only the
" background changes and the tokens keep their colors.
" Derived from the theme instead of hard-coded: take the first candidate that actually
" has a background and whose background differs from the popup's own (Pmenu) and from
" its scrollbar (PmenuThumb/PmenuSbar) -- otherwise the "highlight" is either invisible
" or indistinguishable from the scrollbar. Background only; the foreground is never
" touched so syntax and semantic-token colours survive underneath.
function! s:PeekHl() abort
  let l:avoid = []
  for l:g in ['Pmenu', 'PmenuThumb', 'PmenuSbar']
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
    " Theme offers no distinct background at all -- reverse video works everywhere.
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

" Move the current-line highlight to wherever the cursor now is in the popup.
" Only refresh when the cursor line actually changed -- avoids a redundant
" clearmatches()/matchaddpos() (and its redraw) on every keypress, which is the
" scrolling lag over a remote terminal.
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
    " Jump to the definition location: close the popup and open the target.
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
    " Consume every other key so a stray keypress can never dismiss the float.
    return 1
  endif
  " A movement happened: keep the bg-only current-line highlight on the cursor.
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
  " Read from the live buffer (unsaved edits) if open, else from disk.
  let l:bnr = bufnr(l:file)
  if l:bnr > 0 && bufloaded(l:bnr)
    let l:all = getbufline(l:bnr, 1, '$')
  elseif filereadable(l:file)
    let l:all = readfile(l:file)
  else
    echohl WarningMsg | echom 'Peek: cannot read ' . l:file | echohl None
    return
  endif
  " Show a bounded window around the definition (not the whole file). Highlighting
  " a large whole-file buffer positioned deep re-parses syntax on the first jump
  " into an un-highlighted region -- the visible lag that then caches away. A
  " window keeps syntax instant while still allowing scrolling up (context above)
  " and down (into the body).
  let l:start = get(l:range.start, 'line', 0)
  let l:before = 200
  let l:after  = 500
  let l:winstart = max([l:start - l:before, 0])
  let l:winend   = min([l:start + l:after, len(l:all) - 1])
  let l:content  = l:all[l:winstart : l:winend]
  let l:def_in_popup = l:start - l:winstart + 1
  let l:ft = &filetype
  " Remember the target so the popup's `o` mapping can jump to it.
  let s:peek_file = l:file
  let s:peek_line = l:start + 1
  let s:peek_col  = get(l:range.start, 'character', 0) + 1
  " No 'cursorline': it paints the definition line with PmenuSel (a solid bar)
  " and overrides its syntax highlighting; without it every line is highlighted.
  " Size the popup to a fraction of the current window (not full screen) and
  " center it. border (1 each side) + padding (1 each side) add 4 cols / 2 rows
  " of chrome, subtracted from the target totals below.
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
    " Open with a few lines of context visible ABOVE the definition (comments, the
    " preceding signature, attributes) rather than pinning it to the very top. Clamped
    " so a definition near the start of the file just shows whatever exists above it.
    " Scrolling still reaches the rest in both directions.
    let l:above = min([get(g:, 'peek_context_above', 3), l:def_in_popup - 1])
    call win_execute(l:winid, 'setlocal scrolloff=0')
    call win_execute(l:winid, printf('call winrestview({"lnum": %d, "col": 0, "topline": %d})',
          \ l:def_in_popup, l:def_in_popup - l:above))
    if !empty(l:ft)
      call win_execute(l:winid, 'setlocal filetype=' . l:ft)
    endif
    " Highlight the definition line (bg only; syntax/semantic tokens preserved).
    let s:peek_marked_line = -1
    call s:PeekMark(l:winid)
  endif
endfunction
" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>
let g:coc_global_extensions = ['coc-clangd', 'coc-sh', 'coc-diagnostic', 'coc-highlight', 'coc-rust-analyzer']

" Hover
function! s:show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
    elseif (coc#rpc#ready())
        call CocActionAsync('doHover')
    else
        execute '!' . &keywordprg . " " . expand('<cword>')
    endif
endfunction
" Highlight the symbol and its references when holding the cursor.
" Augrouped so `:source $MYVIMRC` replaces rather than appends.
augroup vimrc_coc_extra
  autocmd!
  autocmd CursorHold * silent call CocActionAsync('highlight')
augroup END
" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>il :CocCommand document.toggleInlayHint <CR>
nmap <leader>ic :call CocAction('showIncomingCalls') <CR>
nmap <leader>oc :call CocAction('showOutgoingCalls') <CR>
" Close coc tree panels (incoming/outgoing calls, outline) with q
" NOTE: no `autocmd!` -- it would wipe the CursorHold entry above.
augroup vimrc_coc_extra
  autocmd FileType coctree nnoremap <silent><buffer> q :close<CR>
augroup END


augroup mygroup
    autocmd!
    " Setup formatexpr specified filetype(s).
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ca  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
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

" " Remap <C-f> and <C-b> for scroll float windows/popups.
" if has('nvim-0.4.0') || has('patch-8.2.0750')
"     nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
"     nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
"     inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
"     inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
"     vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
"     vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
" endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
" nmap <silent> <C-s> <Plug>(coc-range-select)
" xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')
command! -nargs=0 Inspect :CocCommand semanticTokens.inspect

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>sbd  :<C-u>CocList diagnostics<cr>
" Manage extensions.
" nnoremap <silent><nowait> <space>coce  :<C-u>CocList extensions<cr>
" Show commands.
" nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <Leader>fu  :<C-u>CocList outline<cr>
" Search workspace symbols.
" nnoremap <silent><nowait> <space>sym  :<C-u>CocList -I symbols<cr>

