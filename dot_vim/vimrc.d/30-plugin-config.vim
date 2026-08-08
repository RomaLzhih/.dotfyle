" ============================================================================
" 30-plugin-config.vim
" ----------------------------------------------------------------------------
" Per-plugin settings: fzf, floaterm, easymotion, incsearch, tmux
" navigator, bookmarks, asynctasks, which-key and friends.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" -----------------------------PLUGIN CONFIG-----------------------------------
if has("gui_running")
  set guifont=Consolas:h12
set guioptions-=l  " Remove the left scrollbar
set guioptions-=r  " Remove the right scrollbar
set guioptions-=m  " Remove the menu bar
set guioptions-=T  " Remove the toolbar
endif

" markdown
let g:vim_markdown_folding_disabled = 1

"  goyo
let g:goyo_width = 95
let g:goyo_height = 99
let g:goyo_linenr = 1
nnoremap <silent> <Leader>cb :Goyo<CR>

" Far 
nnoremap <silent> <Leader>S :Farr<CR>

" tmux navigator
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-h> :<C-U>TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :<C-U>TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :<C-U>TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :<C-U>TmuxNavigateRight<cr>

tnoremap <silent> <C-h> <C-\><C-n><C-w>h
tnoremap <silent> <C-j> <C-\><C-n><C-w>j
tnoremap <silent> <C-k> <C-\><C-n><C-w>k
tnoremap <silent> <C-l> <C-\><C-n><C-w>l

" Copilot chat
" nnoremap <C-a> :CopilotChatToggle<CR>
" vnoremap <C-a> <Plug>CopilotChatAddSelection
" let g:copilot_reuse_active_chat = 1

" Copilot Terminal Toggle for Vim
" Toggle a terminal running GitHub Copilot CLI on the right side
let g:copilot_term_buf = -1
let g:copilot_term_win = -1

function! s:ToggleCopilotTerminal()
    " Check if the terminal buffer exists
    if g:copilot_term_buf != -1 && bufexists(g:copilot_term_buf)
        " Terminal buffer exists, check if it's visible
        let l:term_win = bufwinnr(g:copilot_term_buf)
        
        if l:term_win != -1
            " Terminal is visible, hide it
            execute l:term_win . 'wincmd w'
            hide
            wincmd p
            let g:copilot_term_win = -1
        else
            " Terminal is hidden, show it
            let l:term_width = &columns / 2
            execute 'vertical rightbelow ' . l:term_width . 'split'
            execute 'buffer ' . g:copilot_term_buf
            let g:copilot_term_win = win_getid()
            " Force disable line numbers when showing the terminal
            setlocal nonumber norelativenumber
        endif
    else
        " Terminal doesn't exist, create it for the first time
        let l:term_width = &columns / 2
        execute 'vertical rightbelow ' . l:term_width . 'split'
        
        let g:copilot_term_buf = term_start('copilot', {
            \ 'term_name': 'Copilot Terminal',
            \ 'term_finish': 'close',
            \ 'curwin': 1,
            \ 'vertical': 1
            \ })
        
        let g:copilot_term_win = win_getid()
        " Force disable line numbers when creating the terminal
        setlocal nonumber norelativenumber
    endif
endfunction

" Autocommand to ensure line numbers stay off in the terminal buffer
augroup CopilotTerminalSettings
    autocmd!
    autocmd BufEnter * if exists('g:copilot_term_buf') && bufnr('%') == g:copilot_term_buf | setlocal nonumber norelativenumber | endif
    autocmd BufWinEnter * if exists('g:copilot_term_buf') && bufnr('%') == g:copilot_term_buf | setlocal nonumber norelativenumber | endif
augroup END

command! ToggleCopilotTerm call s:ToggleCopilotTerminal()
nnoremap <leader>aa :ToggleCopilotTerm<CR>
tnoremap <leader>aa <C-w>:ToggleCopilotTerm<CR>

" Copilot cmp
imap <silent><script><expr> <C-e> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = v:true

" remove useless auto pairs in cpp and latex
" One augroup per file, so `:source $MYVIMRC` replaces rather than appends.
" `autocmd!` appears ONCE per file, here -- later vimrc_plugins blocks
" must NOT repeat it.
augroup vimrc_plugins
  autocmd!
  autocmd FileType cpp let delimitMate_matchpairs = "(:),[:],{:}"
augroup END

" smooth scroll
let g:smoothie_experimental_mappings = 1

" cool total match conut
let g:cool_total_matches = 1

" vimtex
if has('win32') || has('win64')
    let g:vimtex_view_method = 'SumatraPDF'
elseif has('mac')
    let g:vimtex_view_method = 'skim'
else
    let g:vimtex_view_method = 'zathura'
endif
let g:vimtex_quickfix_open_on_warning = 0
let g:vimtex_syntax_conceal_disable = 1
let g:vimtex_compiler_latexmk = {
    \ 'continuous' : 1,
    \}
" <buffer> added: without it this global map leaks into every other buffer once
" any .tex file has been opened. (It already worked -- Vim remaps a <Plug> rhs
" even from a noremap -- so this is a scope fix, not a resurrection.)
augroup vimrc_plugins
  autocmd FileType tex nmap <buffer> <Leader>mk <Plug>(vimtex-compile)
augroup END

" air line
" --- airline startup cost (was ~84ms of a ~205ms startup) ---
" Pinning the theme sets s:theme_in_vimrc, so airline skips its startup theme
" probe (switch_matching_theme -> switch_theme -> load_theme) and applies the
" palette ONCE instead of twice. The AirlineFollowColorscheme augroup in
" 40-colorscheme.vim restores the one thing this removes -- following the
" colourscheme when one is picked at runtime -- so <leader>th still works.
" These two MUST stay together.
let g:airline_theme = 'gruvbox'
" Memoise highlight-group lookups. Without this, get_highlight() re-derives every
" group from synIDattr() on each call (332 calls / 1472 synIDattr at startup;
" 189 / 456 with it). The cache is flushed by reset_hlcache() on every
" ColorScheme and :AirlineRefresh, so <leader>th stays correct.
let g:airline_highlighting_cache = 1
" DELIBERATELY NOT SET: g:airline_extensions.
" Naming the extensions explicitly skips airline's auto-detection block and saved
" ~3ms, but it is not safe here. With a list, airline#extensions#load() calls
" airline#extensions#{name}#init() blindly; 7 of the 16 extension files begin with
" a conditional `finish` (netrw needs :NetrwSettings, hunks needs g:loaded_signify,
" bookmark needs :BookmarkToggle, fugitiveline needs FugitiveHead, obsession needs
" ObsessionStatus, searchcount needs *searchcount, keymap needs +keymap). Those
" conditions depend on plugins that load AFTER this vimrc, so a file can finish
" early, leave no init(), and airline reports
"   "airline: Extension 'netrw' not installed, ignoring!"
" at every startup. Auto-detection gates each one at the right moment; a static
" list cannot. The 3ms is not worth it -- the real airline win is the two settings
" above (~34ms of the ~37ms).
let g:airline#extensions#tabline#enabled = 1
" Show only the file name in the tabline (no abbreviated /b/a/d/ path prefix)
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_left_sep='>'
let g:airline#extensions#whitespace#enabled = 0
" (Removed: `au VimEnter * let [g:airline_section_y] = [airline#section#create([''])]`.
"  It was a no-op -- airline#section#create(['']) returns '', and vim-devicons
"  overwrites the WINDOW-local w:airline_section_y on every rebuild, which beats
"  the global. Section y renders identically without it. To actually blank that
"  slot, set g:webdevicons_enable_airline_statusline_fileformat_symbols = 0.)

" git operation
nnoremap <Leader>git :Git<CR>

" fzf
" (Was wrapped in `if has('win32')` / else, with the win32 branch setting
"  g:ctrlp_map / g:ctrlp_cmd -- but ctrlp is not installed, so that branch left
"  no file-finder at all. Dropped the guard along with the dead ctrlp settings.)
let $FZF_DEFAULT_OPTS = '--bind tab:up,shift-tab:down,ctrl-d:toggle,ctrl-a:toggle-all --cycle --multi'
" Make :BLines match other fzf windows: default layout so the cursor starts
" at the bottom and <Tab> (bound to 'up') moves upward
let g:fzf_blines_options = ['--layout=default']

nnoremap <C-f> :Files <CR>
nnoremap ? :BLines <CR>
nnoremap <Leader>ff :Files <CR>
nnoremap <Leader>gf :GFiles <CR>
nnoremap <Leader>fw :RG<CR>
nnoremap <Leader>gw :Rg <C-R><C-W><CR>
nnoremap <Leader>bb :Buffers<CR>
nnoremap <Leader>fj :Jumps<CR>
nnoremap <Leader>fm :Marks<CR>

" colorscheme picker
" Colourschemes are registered {'on': []} in 00-plugins.vim: installed but off
" 'runtimepath', so getcompletion('','color') cannot see them and :colorscheme
" would fail with E185. s:colorscheme_preload() puts the owning plugin back from
" ColorSchemePre -- i.e. before Vim looks for colors/<name>.vim -- so plain
" plain `:colorscheme nord` and 40-colorscheme.vim keep working.
" The picker builds its own list because getcompletion() cannot see them.
function! s:colorscheme_owners() abort
  let l:map = {}
  for l:name in getcompletion('', 'color')
    let l:map[l:name] = ''
  endfor
  for l:plug in keys(g:plugs)
    for l:f in glob(g:plugs[l:plug].dir . 'colors/*.vim', 0, 1)
      let l:map[fnamemodify(l:f, ':t:r')] = l:plug
    endfor
  endfor
  return l:map
endfunction

" Fast path: only pay for the scan when the scheme is not already on
" 'runtimepath', so the one ColorScheme at startup costs a single globpath.
function! s:colorscheme_preload(name) abort
  if empty(a:name) || !empty(globpath(&rtp, 'colors/' . a:name . '.vim', 1))
    return
  endif
  let l:owner = get(s:colorscheme_owners(), a:name, '')
  if !empty(l:owner)
    silent! call plug#load(l:owner)
  endif
endfunction

augroup ColorschemeLazyLoad
  autocmd!
  autocmd ColorSchemePre * call s:colorscheme_preload(expand('<amatch>'))
augroup END

" Function to provide the list of available color schemes to fzf
function! s:list_colorschemes()
  return sort(keys(s:colorscheme_owners()))
endfunction

" Function to apply the selected color scheme
function! s:set_colorscheme(scheme)
  exec 'colorscheme ' . fnameescape(a:scheme)
endfunction

" Main function to configure and run fzf for changing color schemes
function! FzfColorschemes()
  call fzf#run(fzf#wrap({
			\ 'source':  s:list_colorschemes(),
			\ 'sink':    function('s:set_colorscheme'),
			\ 'options': '--prompt="Color Schemes> " --preview="colorscheme {}" --preview-window=up:40%:hidden',
			\ 'down':    '40%'
			\ }))
endfunction
" The non-recursive mapping in normal mode
nnoremap <Leader>th :call FzfColorschemes()<CR>

" float term
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8
let g:floaterm_keymap_new    = '<F1>'
let g:floaterm_keymap_prev   = '<F2>'
let g:floaterm_keymap_next   = '<F3>'
let g:floaterm_keymap_kill   = '<F4>'
let g:floaterm_keymap_toggle = '<C-g>'
tnoremap   <silent>   <C-x>   <C-\><C-n>

" lazygit in floaterm
function! LazyGitFloaterm()
    FloatermNew --height=0.9 --width=0.9 --wintype=float --position=center --autoclose=2 lazygit
endfunction
nnoremap <leader>lg :call LazyGitFloaterm()<CR>

" vim-which-key
nnoremap <silent> <leader>      :<c-u>WhichKey '<Space>'<CR>
" nnoremap <silent> <localleader> :<c-u>WhichKey  '\'<CR>

" Yazi
nnoremap <C-s> :Yazi<CR>

" asynctasks
function! s:list_async_tasks()
	let rows = asynctasks#source(&columns * 48 / 100)
	let source = []
	for row in rows
		let source += [printf('%s  %s  : %s', row[0], row[1], row[2])]
	endfor
	return source
endfunction

function! s:fzf_sink(line)
	" Extract the task name, which is the first part of the string
	let task_name = split(a:line, '  ')[0]
	if !empty(task_name)
		exec "AsyncTask" fnameescape(task_name)
	endif
endfunction

command! -nargs=0 AsyncTaskFzf call fzf#run(fzf#wrap({
			\ 'source': s:list_async_tasks(),
			\ 'sink': function('s:fzf_sink'),
			\ 'options': '+m --nth 1 --inline-info --tac'
			\ }))

let g:asyncrun_open = 15
let g:asynctasks_term_reuse = 1
let g:asynctasks_template = '~/.vim/task_template.ini'
let g:asynctasks_term_pos = 'bottom'
nnoremap <Leader>ob :AsyncTaskFzf<CR>
nnoremap <Leader>ol :AsyncTaskLast<CR>
nnoremap <Leader>ru :AsyncTaskEdit<CR>
nnoremap <Leader>st :AsyncStop<CR>

" easy motion
" ('set smartcase' lives in 10-options.vim; nothing clears it in between.)
let g:EasyMotion_smartcase = 1
let g:EasyMotion_do_mapping = 0
augroup vimrc_plugins
  autocmd User EasyMotionPromptBegin :let b:coc_diagnostic_disable = 1
  autocmd User EasyMotionPromptEnd :let b:coc_diagnostic_disable = 0
augroup END

map  f <Plug>(easymotion-fl)
map  F <Plug>(easymotion-Fl)
map  t <Plug>(easymotion-tl)
map  T <Plug>(easymotion-Tl)
nmap s <Plug>(easymotion-overwin-f2)
" map  / <Plug>(easymotion-sn)

let g:incsearch#smartcase = 1

function! s:incsearch_config(...) abort
  return incsearch#util#deepextend(deepcopy({
  \   'modules': [incsearch#config#easymotion#module({'overwin': 1})],
  \   'keymap': {
  \     "\<CR>": '<Over>(easymotion)'
  \   },
  \   'is_expr': 0,
  \   'is_stay': 0
  \ }), get(a:, 1, {}))
endfunction
noremap <silent><expr> /  incsearch#go(<SID>incsearch_config())

function! s:config_easyfuzzymotion(...) abort
  return extend(copy({
  \   'converters': [incsearch#config#fuzzyword#converter()],
  \   'modules': [incsearch#config#easymotion#module({'overwin': 1})],
  \   'keymap': {"\<CR>": '<Over>(easymotion)'},
  \   'is_expr': 0,
  \   'is_stay': 0
  \ }), get(a:, 1, {}))
endfunction

noremap <silent><expr> <leader>/ incsearch#go(<SID>config_easyfuzzymotion())

" bookmarks: store per project (not one global file), kept in a central folder
" so project dirs stay clean. Change g:bookmark_dir to relocate; delete the
" function below to use a plain ./.vim-bookmarks in each project instead.
let g:bookmark_save_per_working_dir = 1
" Close the bookmark quickfix list automatically after jumping to a bookmark.
let g:bookmark_auto_close = 1
let g:bookmark_dir = expand('$HOME/.local/state/vim/bookmarks')
call mkdir(g:bookmark_dir, 'p')
function! g:BMWorkDirFileLocation()
    return g:bookmark_dir . '/' . substitute(getcwd(), '[\\/:]', '%', 'g') . '.vim-bookmarks'
endfunction
nmap <Leader>ha <Plug>BookmarkToggle
nmap <Leader>hh <Plug>BookmarkShowAll
nmap <Leader>hn <Plug>BookmarkNext
nmap <Leader>hp <Plug>BookmarkPrev
nmap <Leader>hc <Plug>BookmarkClear
nmap <Leader>hx <Plug>BookmarkClearAll

" In the bookmark quickfix list (opened by <Leader>hh), press 1-9 to jump
" straight to that bookmark (:cc N). Scoped by the qf title so count-prefixed
" motions still work in other quickfix lists (grep, errors, etc.).
" The maps are cleared when the same qf buffer is reused for a non-bookmark list.
function! s:BookmarkQfNumberMaps() abort
  let l:is_bm = getqflist({'title': 1}).title =~# 'bm#location_list'
  for n in range(1, 9)
    if l:is_bm
      execute printf('nnoremap <silent><buffer><nowait> %d :cc %d<CR>', n, n)
    else
      silent! execute printf('nunmap <buffer> %d', n)
    endif
  endfor
endfunction
augroup vimrc_plugins
  autocmd FileType qf call s:BookmarkQfNumberMaps()
augroup END

" NOTE: indentLine
" The guides were being drawn all along, but in the `Conceal` colour: #504945 on
" gruvbox's #282828 background is a 1.65:1 contrast ratio, i.e. invisible. Point it
" at a highlight group instead of a hex colour -- indentLine re-reads the group on
" every ColorScheme/Syntax event, so this stays correct in any theme, including ones
" installed later. LineNr is defined in all 52 themes here and averages 5.36:1.
" Swap in 'Comment' (5.94:1 mean) if you want the guides more prominent.
let g:indentLine_defaultGroup = 'LineNr'

" ...but gruvbox, gruvbox-material and everforest hard-code g:indentLine_color_gui to a
" very dim background shade, and in indentLine's InitColor() an explicit colour beats
" defaultGroup -- which is why the guides were invisible. Drop that variable once the
" theme has finished loading so the group choice wins again. This augroup is registered
" before indentLine's own (it loads from after/plugin, i.e. later), so on a ColorScheme
" event ours runs first and indentLine then recomputes the colour from LineNr.
augroup IndentLineUseGroupColor
  autocmd!
  autocmd ColorScheme * silent! unlet g:indentLine_color_gui
  autocmd ColorScheme * silent! unlet g:indentLine_color_term
augroup END

" LaTeX: disable indentLine per buffer rather than globally. The old
" `let g:indentLine_setConceal = 0` was global, so opening one .tex file killed the
" guides in every other buffer for the rest of the session. b:indentLine_enabled is
" checked before indentLine touches 'conceallevel', so vimtex's own conceal setup is
" still left alone -- which was the point of the original line.
augroup vimrc_plugins
  autocmd FileType tex,bib let b:indentLine_enabled = 0
augroup END

