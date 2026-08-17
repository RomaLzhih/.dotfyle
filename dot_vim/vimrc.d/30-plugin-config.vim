" 30-plugin-config.vim -- per-plugin settings: fzf, floaterm, easymotion,
" incsearch, tmux navigator, airline, context, bookmarks, asynctasks, which-key.

if has("gui_running")
  set guifont=Consolas:h12
set guioptions-=l  " Remove the left scrollbar
set guioptions-=r  " Remove the right scrollbar
set guioptions-=m  " Remove the menu bar
set guioptions-=T  " Remove the toolbar
endif

" markdown
let g:vim_markdown_folding_disabled = 1

" goyo
let g:goyo_width = 95
let g:goyo_height = 99
let g:goyo_linenr = 1
nnoremap <silent> <Leader>cb :Goyo<CR>

" far
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

" vim-visual-multi: give <C-Up>/<C-Down> to the resize maps in 20-. VM claims them
" by default and, being deferred, loads after vimrc.d and overwrites -- unlike
" unimpaired it does not check first. g:VM_maps merges, so <C-n> etc. are untouched.
let g:VM_maps = {}
let g:VM_maps['Add Cursor Down'] = '<Leader>mj'
let g:VM_maps['Add Cursor Up']   = '<Leader>mk'

" Copilot chat
" nnoremap <C-a> :CopilotChatToggle<CR>
" vnoremap <C-a> <Plug>CopilotChatAddSelection
" let g:copilot_reuse_active_chat = 1

" Copilot completion
imap <silent><script><expr> <C-e> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = v:true
" copilot arms a timer on every CursorMovedI and then ships a FULL-BUFFER didChange
" (the Vim transport has no incremental sync -- 92KB on fork.c per trigger). At the
" default 45ms that fires while you are still typing; at 150 each keystroke restarts
" it, so it never fires mid-typing: insert ttlb p50 48.6ms -> 8.8ms.
" Cost: ghost text ~105ms later after you stop. Undocumented, so re-check on upgrade.
let g:copilot_idle_delay = 150

" One augroup per file; only this FIRST block carries `autocmd!`.
augroup vimrc_plugins
  autocmd!
  autocmd FileType cpp let delimitMate_matchpairs = "(:),[:],{:}"
augroup END

" vim-signature: the periodic sign refresh was the most expensive thing on the idle
" path -- 2.55ms of a 3.15ms CursorHold, and size-independent, so every buffer pays.
" Marks still get signs; only the periodic reconciliation is lost, so a mark changed
" by :delmarks or a viminfo restore can show stale until signature#sign#Refresh().
let g:SignaturePeriodicRefresh = 0

" vim-devicons, two pure-waste costs:
" (1) NERDTree is not installed, but devicons registers a CursorHold handler anyway
"     that only ever hits its early return (0.13ms per idle tick).
let g:webdevicons_enable_nerdtree = 0

" (2) WebDevIconsGetFileTypeSymbol() is unmemoised and called per buffer per tabline
"     rebuild. Half of each 86us call walks 9 JS/Vagrantfile regexes that cannot
"     match a source path here; clearing them gives 44us. No icon is lost -- vimrc
"     and .vim are in the exact/extension dicts. On VimEnter because devicons
"     re-merges its defaults at plugin-load time, i.e. after vimrc.d.
augroup vimrc_devicons
  autocmd!
  autocmd VimEnter * ++once let g:WebDevIconsUnicodeDecorateFileNodesPatternSymbols = {}
augroup END

" ---- context.vim: sticky context header (nvim-treesitter-context equivalent) ----
let g:context_enabled = 1
" The default 21 can swallow a third of the window on deeply nested code.
let g:context_max_height = 10
let g:context_max_per_indent = 3
" '<hide>' is a sentinel, not a group: it drops the "<context.vim>" label from the
" separator. Use g:context_highlight_border = '<hide>' to drop the whole line.
let g:context_highlight_tag = '<hide>'
let g:context_filetype_blacklist = ['startify', 'qf', 'coctree', 'floaterm', 'fzf', 'help', 'man']
let g:context_buftype_blacklist  = ['terminal', 'quickfix', 'nofile', 'help']
" Its <C-E>/<C-Y>/zz/zb maps are gated on !exists('##WinScrolled') and Vim 9.1 has
" it, so they never run. It does take zt and H, which nothing here wanted.

" Large-file gate, mirroring nvim's treesitter-context cutoff. Registering the
" events ourselves rather than using :ContextDisableWindow, because that does not
" actually stop the work: context#update() calls update_state() BEFORE its active()
" test, and update_state toggles 'conceallevel' -- a redraw-window option, so every
" cursor move forced a full syntax re-highlight even with the header off. (That cost
" is invisible to :profile, which times vimscript, not the redraw it schedules.)
" Measured on fork.c at 200x50: 1.83ms per cursor move before, 0.19ms after.
" g:context_add_autocmds=0 gates off context.vim's whole augroup, including its
" VimEnter ContextActivate -- hence the explicit call below.
let g:context_size_limit = 2000
let g:context_add_autocmds = 0

function! s:ContextSizeGate() abort
  let l:big = line('$') > g:context_size_limit
  let w:vimrc_context_off = l:big
  if !exists(':ContextEnableWindow')
    return
  endif
  " Read the real state from w:context rather than our own transition flag, so a
  " window context.vim re-initialised is noticed. -1 == not initialised yet.
  let l:on = get(get(w:, 'context', {}), 'enabled', -1)
  if l:big && l:on == 1
    ContextDisableWindow
  elseif !l:big && l:on == 0
    ContextEnableWindow
  endif
endfunction

function! s:ContextUpdate(source) abort
  if get(w:, 'vimrc_context_off', 0)
    return
  endif
  call context#update(a:source)
endfunction

augroup vimrc_context
  autocmd!
  autocmd BufWinEnter,BufEnter * call s:ContextSizeGate()
  " Re-apply the gate after activation, which rebuilds w:context with enabled=1.
  autocmd VimEnter * call s:ContextSizeGate()
        \ | ContextActivate
        \ | if get(w:, 'vimrc_context_off', 0) | ContextDisableWindow | endif
  " context.vim's own event list, each behind the size gate.
  autocmd BufAdd       * call s:ContextUpdate('BufAdd')
  autocmd BufEnter     * call s:ContextUpdate('BufEnter')
  autocmd CursorMoved  * call s:ContextUpdate('CursorMoved')
  autocmd WinScrolled  * call s:ContextUpdate('WinScrolled')
  autocmd CursorHold   * call s:ContextUpdate('CursorHold')
  autocmd VimResized   * call s:ContextUpdate('VimResized')
  autocmd OptionSet number,relativenumber,numberwidth,signcolumn,tabstop,list
        \ call s:ContextUpdate('OptionSet')
augroup END

" smooth scroll
let g:smoothie_experimental_mappings = 1

" DELIBERATELY 0. vim-cool does not use searchcount(): it walks the whole buffer
" with `norm! n` once per match, then forces a redraw, on every CursorMoved while
" the cursor is on a match. 6.2ms for /struct on fork.c, and it gives up past 100ms
" anyway. airline's searchcount extension already shows the same number.
" Only the echo is lost; auto-:nohlsearch is unaffected.
let g:cool_total_matches = 0

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
" <buffer> or this global map leaks into every buffer once a .tex is opened.
augroup vimrc_plugins
  autocmd FileType tex nmap <buffer> <Leader>mk <Plug>(vimtex-compile)
augroup END

" ---- airline (was ~84ms of a ~205ms startup) ----
" Pinning the theme sets s:theme_in_vimrc, so airline skips its startup theme probe
" and applies the palette once instead of twice. The AirlineFollowColorscheme
" augroup in 40- restores runtime switching. THESE TWO MUST STAY TOGETHER.
let g:airline_theme = 'gruvbox'
" Memoise highlight lookups: 332 calls/1472 synIDattr at startup, 189/456 with it.
" Flushed on ColorScheme and :AirlineRefresh, so <leader>th stays correct.
let g:airline_highlighting_cache = 1
" DELIBERATELY NOT SET: g:airline_extensions. A static list makes
" airline#extensions#load() call init() blindly, but 7 of 16 extension files begin
" with a conditional `finish` that depends on plugins loading AFTER this vimrc --
" so they finish early, leave no init(), and airline warns at every startup.
" Auto-detection gates each at the right moment; the 3ms is not worth it.
let g:airline#extensions#tabline#enabled = 1
" Tabline reads "<icon> parent/file.c" -- enough to tell apart same-named files.
" Implemented in autoload/airline/extensions/tabline/formatters/parentfile.vim,
" because airline resolves formatters by autoload path. Devicons' own hook is off:
" it appends the glyph AFTER the name and would swap in its own formatter.
let g:airline#extensions#tabline#formatter = 'parentfile'
let g:webdevicons_enable_airline_tabline = 0
" Renders identically at 0; purely to stop work. buffers#get() calls s:map_keys()
" before its own cache check, and map_keys defaults to 1 while the render paths
" default to 0 -- so 14 <Plug> :noremap commands were re-run on every tabline
" redraw (0.073s over a 155-keystroke profile). Nothing here uses AirlineSelect.
let g:airline#extensions#tabline#buffer_idx_mode = 0
" DELIBERATELY NOT SET: g:airline_skip_empty_sections. It eval()s every %{...} in a
" section on each build, on top of the redraw-time evaluation, and would double
" exactly the expensive chain (section b: hunks + branch).
let g:airline_left_sep='>'
let g:airline#extensions#whitespace#enabled = 0

" ---- section c: path relative to the project root ----
" airline's 'file' part is `%f`, which Vim renders relative to the CWD -- so it goes
" absolute the moment you open something outside it, and this config never auto-cds.
" g:airline_stl_path_style='gitrepo' goes through FugitiveFind, so it is git-only and
" falls back to the full path; fbsource is Sapling. Hence the marker walk below.
" A raw string, not airline#section#create(), so nothing forces airline's autoload
" during startup. Mirrors airline's own default section c.
let g:airline_section_c = '%<%{AirlineProjectPath()}%m '
      \ . '%{airline#util#wrap(airline#parts#readonly(),0)}'
      \ . '%{airline#util#wrap(airline#extensions#coc#get_status(),0)}'

" Deepest marker wins, so a git checkout inside an hg repo resolves to the inner
" one. Cached per buffer: a miss is a full walk to /, and this runs on every redraw.
function! s:AirlineProjectRoot(full) abort
  let l:dir = fnamemodify(a:full, ':h')
  let l:best = ''
  for l:marker in ['.git', '.hg', '.sl']
    " .git is a FILE, not a directory, in worktrees and submodules.
    let l:hit = finddir(l:marker, l:dir . ';')
    let l:root = empty(l:hit) ? '' : fnamemodify(l:hit, ':p:h:h')
    if empty(l:root)
      let l:hit = findfile(l:marker, l:dir . ';')
      let l:root = empty(l:hit) ? '' : fnamemodify(l:hit, ':p:h')
    endif
    if len(l:root) > len(l:best)
      let l:best = l:root
    endif
  endfor
  return l:best
endfunction

function! AirlineProjectPath() abort
  if empty(bufname('%'))
    return &buftype ==# 'nofile' ? '[Scratch]' : '[No Name]'
  endif
  " terminals, quickfix, coctree: a project path is meaningless
  if &buftype !=# '' && &buftype !=# 'help'
    return expand('%:t')
  endif
  let l:full = expand('%:p')
  if get(b:, 'airline_pp_src', '') ==# l:full && exists('b:airline_pp')
    return b:airline_pp
  endif
  " Compare RESOLVED paths on both sides: fnamemodify(':p') resolves symlinks and
  " expand('%:p') does not, and ~/fbsource is a link here -- without this the prefix
  " test fails and every fbsource file falls back to the cwd-relative path.
  let l:root = s:AirlineProjectRoot(l:full)
  let l:rfull = resolve(l:full)
  let l:rroot = empty(l:root) ? '' : resolve(l:root)
  if !empty(l:rroot) && l:rfull[: len(l:rroot) - 1] ==# l:rroot
    let b:airline_pp = l:rfull[len(l:rroot) + 1 :]
  else
    " no VCS root, or file outside it: cwd-relative, i.e. what %f did
    let b:airline_pp = fnamemodify(l:full, ':.')
  endif
  let b:airline_pp_src = l:full
  return b:airline_pp
endfunction

" git
nnoremap <Leader>git :Git<CR>

" ---- fzf ----
let $FZF_DEFAULT_OPTS = '--bind tab:up,shift-tab:down,ctrl-d:toggle,ctrl-a:toggle-all --cycle --multi'
" Default layout so :BLines starts at the bottom and <Tab> (bound to 'up') moves up.
let g:fzf_blines_options = ['--layout=default']

nnoremap <C-f> :Files <CR>
nnoremap ? :BLines <CR>
nnoremap <Leader>ff :Files <CR>
nnoremap <Leader>gf :GFiles <CR>
nnoremap <Leader>fw :RG<CR>
nnoremap <Leader>gw :Rg <C-R><C-W><CR>
nnoremap <Leader>bb :Buffers<CR>
" Recent files in this project (nvim has it on <A-w>, unusable here).
" _recent_files() formats with ':~:.', so entries under the cwd come back relative
" and everything else starts with '/' or '~' -- that leading char IS the scope.
" fzf.vim's own :History remains, unmapped, for the global list.
command! -bang HistoryCwd call fzf#run(fzf#wrap('historycwd', {
      \ 'source':  filter(fzf#vim#_recent_files(), 'v:val !~# "^[~/]"'),
      \ 'options': ['--prompt', 'RecentHere> '],
      \ }, <bang>0))
nnoremap <Leader>fr :HistoryCwd<CR>
" : command history. <CR> runs it, <C-e> edits it first -- both fzf.vim's own
" behaviour. ':History:' with the trailing colon dispatches to command_history();
" ':History/' is the search-history equivalent. <Leader>: matches LazyVim's key.
nnoremap <Leader>: :History:<CR>

" fugitive: :Git is left exactly as shipped -- the half-height split. (Earlier
" revisions forced `:tab Git` or `:0Git`; both are one cnoreabbrev away.)
" What IS customised: you cannot cycle a buffer over the top of it. These buffers
" are bufhidden=delete, so switching away destroys the split rather than hiding it.
" This is the b-family counterpart to the guard in SwitchBuffer() (20-). gq exits.
" Guarded on &buftype, not b:fugitive_type: the pagers set their filetype before
" the rest of their setup, so the b: variable is not reliably there yet.
" Emulation, not enforcement -- 'winfixbuf' needs 9.1.0147, this Vim is .0113.
" Must sit after the augroup that owns this file's `autocmd!`.
augroup vimrc_plugins
  autocmd FileType fugitive,git,fugitiveblame
        \ if &buftype !=# '' |
        \   for s:k in [']b', '[b', ']B', '[B'] |
        \     execute 'nnoremap <buffer><nowait> ' . s:k . ' <Nop>' |
        \   endfor |
        \ endif
augroup END

nnoremap <Leader>fj :Jumps<CR>
" Moved off <Leader>fm, which is :Format in 50-coc.vim (k = marK).
nnoremap <Leader>fk :Marks<CR>

" ---- colourscheme picker ----
" Schemes are {'on': []} in 00-, so they are off 'runtimepath' and getcompletion()
" cannot see them. Preloading the owner from ColorSchemePre -- before Vim looks for
" colors/<name>.vim -- keeps plain `:colorscheme nord` working.
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

" Fast path: only scan when the scheme is not already on 'runtimepath', so the one
" ColorScheme at startup costs a single globpath.
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

function! s:list_colorschemes()
  return sort(keys(s:colorscheme_owners()))
endfunction

function! s:set_colorscheme(scheme)
  exec 'colorscheme ' . fnameescape(a:scheme)
endfunction

function! FzfColorschemes()
  call fzf#run(fzf#wrap({
			\ 'source':  s:list_colorschemes(),
			\ 'sink':    function('s:set_colorscheme'),
			\ 'options': '--prompt="Color Schemes> " --preview="colorscheme {}" --preview-window=up:40%:hidden',
			\ 'down':    '40%'
			\ }))
endfunction
nnoremap <Leader>th :call FzfColorschemes()<CR>

" ---- floaterm ----
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8
let g:floaterm_keymap_new    = '<F1>'
let g:floaterm_keymap_prev   = '<F2>'
let g:floaterm_keymap_next   = '<F3>'
let g:floaterm_keymap_kill   = '<F4>'
let g:floaterm_keymap_toggle = '<C-g>'
tnoremap   <silent>   <C-x>   <C-\><C-n>

function! LazyGitFloaterm()
    FloatermNew --height=0.9 --width=0.9 --wintype=float --position=center --autoclose=2 lazygit
endfunction
nnoremap <leader>lg :call LazyGitFloaterm()<CR>

" which-key
nnoremap <silent> <leader>      :<c-u>WhichKey '<Space>'<CR>
" nnoremap <silent> <localleader> :<c-u>WhichKey  '\'<CR>

" yazi
nnoremap <C-s> :Yazi<CR>

" ---- asynctasks ----
function! s:list_async_tasks()
	let rows = asynctasks#source(&columns * 48 / 100)
	let source = []
	for row in rows
		let source += [printf('%s  %s  : %s', row[0], row[1], row[2])]
	endfor
	return source
endfunction

function! s:fzf_sink(line)
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

" ---- easymotion / incsearch ----
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

" ---- bookmarks ----
" Per project, in a central folder so project dirs stay clean.
let g:bookmark_save_per_working_dir = 1
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

" In the <Leader>hh list: 1-9 jump to a slot, `i` edits the annotation, `dd`
" deletes, `K`/`J` reorder. Scoped by the qf title, and cleared when the same qf
" buffer is reused for a non-bookmark list.
function! s:BookmarkQfIsList() abort
  return getqflist({'title': 1}).title =~# 'bm#location_list'
endfunction

function! s:BookmarkQfMaps() abort
  let l:is_bm = s:BookmarkQfIsList()
  for n in range(1, 9)
    if l:is_bm
      execute printf('nnoremap <silent><buffer><nowait> %d :cc %d<CR>', n, n)
    else
      silent! execute printf('nunmap <buffer> %d', n)
    endif
  endfor
  if l:is_bm
    nnoremap <silent><buffer><nowait> i  :call <SID>BookmarkQfAnnotate()<CR>
    nnoremap <silent><buffer><nowait> dd :call <SID>BookmarkQfDelete()<CR>
    nnoremap <silent><buffer><nowait> K  :call <SID>BookmarkQfMove(-1)<CR>
    nnoremap <silent><buffer><nowait> J  :call <SID>BookmarkQfMove(1)<CR>
    " ShowAll just filled the list positionally; re-sort before it is drawn.
    call s:BookmarkQfRender()
  else
    for l:key in ['i', 'dd', 'K', 'J']
      silent! execute 'nunmap <buffer> ' . l:key
    endfor
  endif
endfunction

" --- ordering ---
" vim-bookmarks has no order: the list is re-derived from (file, line) and
" serialize() only writes sign_idx/line_nr/content/annotation, so an extra field
" would be dropped -- the plugin reloads from disk on every BufEnter. The order
" therefore lives in a side file of sign_idx values, the one attribute that is both
" stable while editing and round-tripped by the plugin's save format.
" Advisory: unlisted bookmarks sort last, dead entries are dropped, and deleting
" the file just restores positional order.
function! s:BookmarkOrderFile() abort
  return exists('*g:BMWorkDirFileLocation')
        \ ? g:BMWorkDirFileLocation() . '.order'
        \ : g:bookmark_dir . '/global.vim-bookmarks.order'
endfunction

function! s:BookmarkOrderGet() abort
  if get(s:, 'bookmark_order_cwd', '') !=# getcwd()
    let s:bookmark_order_cwd = getcwd()
    let l:file = s:BookmarkOrderFile()
    let s:bookmark_order = filereadable(l:file)
          \ ? filter(map(readfile(l:file), 'str2nr(v:val)'), 'v:val > 0')
          \ : []
  endif
  return s:bookmark_order
endfunction

function! s:BookmarkOrderPut(sign_idxs) abort
  " Never persist an empty order: the plugin drops and reloads its whole model on
  " every BufEnter, so a render catching it mid-reload would truncate the file.
  if empty(a:sign_idxs) || s:BookmarkOrderGet() ==# a:sign_idxs
    return
  endif
  let s:bookmark_order = copy(a:sign_idxs)
  call writefile(map(copy(a:sign_idxs), 'string(v:val)'), s:BookmarkOrderFile())
endfunction

" Every bookmark as {'file','bm','idx'} in display order: saved order first, then
" the rest positionally. str2nr() because the plugin's own refresh rebuilds from
" keys(), turning sign_idx into a string that would persist as quoted junk.
function! s:BookmarkEntries() abort
  let l:by_idx = {}
  let l:positional = []
  for l:file in sort(bm#all_files())
    for l:line_nr in sort(bm#all_lines(l:file), 'bm#compare_lines')
      let l:bm = bm#get_bookmark_by_line(l:file, l:line_nr)
      let l:idx = str2nr(l:bm.sign_idx)
      let l:by_idx[l:idx] = {'file': l:file, 'bm': l:bm, 'idx': l:idx}
      call add(l:positional, l:idx)
    endfor
  endfor
  let l:entries = []
  let l:taken = {}
  for l:idx in s:BookmarkOrderGet() + l:positional
    if has_key(l:by_idx, l:idx) && !has_key(l:taken, l:idx)
      let l:taken[l:idx] = 1
      call add(l:entries, l:by_idx[l:idx])
    endif
  endfor
  return l:entries
endfunction

" Rewrite in place, keeping the qf list and title so 1-9 and detection still work.
function! s:BookmarkQfRender() abort
  let l:entries = s:BookmarkEntries()
  let l:lines = []
  for l:entry in l:entries
    let l:bm = l:entry.bm
    let l:content = l:bm.annotation !=# ''
          \ ? 'Annotation: ' . l:bm.annotation
          \ : (l:bm.content !=# '' ? l:bm.content : 'empty line')
    call add(l:lines, l:entry.file . ':' . l:bm.line_nr . ':' . l:content)
  endfor
  call setqflist([], 'r', {
        \ 'lines': l:lines,
        \ 'efm':   '%f:%l:%m',
        \ 'title': ':cgetexpr bm#location_list()',
        \ })
  call s:BookmarkOrderPut(map(copy(l:entries), 'v:val.idx'))
endfunction

" The explicit save matters: the plugin only auto-saves on BufLeave/VimLeave but
" reloads on every BufEnter, so an edit made from the qf window would be lost.
function! s:BookmarkQfReload(...) abort
  let l:want = a:0 ? a:1 : line('.')
  call s:BookmarkQfRender()
  call BookmarkSave(g:BMWorkDirFileLocation(), 1)
  call cursor(max([1, min([l:want, line('$')])]), 1)
endfunction

function! s:BookmarkQfTarget() abort
  let l:entries = s:BookmarkEntries()
  if empty(l:entries) || len(l:entries) !=# line('$')
    echohl WarningMsg | echo 'Bookmark list is out of date, reopen it with <Leader>hh' | echohl None
    return {}
  endif
  return l:entries[line('.') - 1]
endfunction

function! s:BookmarkQfMove(delta) abort
  let l:entries = s:BookmarkEntries()
  if empty(l:entries) || len(l:entries) !=# line('$')
    echohl WarningMsg | echo 'Bookmark list is out of date, reopen it with <Leader>hh' | echohl None
    return
  endif
  let l:from = line('.') - 1
  let l:to = l:from + a:delta
  if l:to < 0 || l:to >= len(l:entries)
    return
  endif
  let l:idxs = map(copy(l:entries), 'v:val.idx')
  call insert(l:idxs, remove(l:idxs, l:from), l:to)
  call s:BookmarkOrderPut(l:idxs)
  call s:BookmarkQfReload(l:to + 1)
endfunction

function! s:BookmarkQfAnnotate() abort
  let l:target = s:BookmarkQfTarget()
  if empty(l:target)
    return
  endif
  let l:bm = l:target.bm
  let l:old = l:bm['annotation']
  " In the console inputdialog() returns the pre-filled text on <Esc>, so escape
  " lands on the ==# l:old no-op below; C-u then <CR> clears the note.
  let l:new = inputdialog((empty(l:old) ? 'Enter' : 'Edit') .' annotation: ', l:old)
  redraw!
  if l:new ==# l:old
    return
  endif
  call bm#update_annotation(l:target.file, l:bm['sign_idx'], l:new)
  " Annotated bookmarks use a different glyph, so re-place the sign.
  call bm_sign#update_at(l:target.file, l:bm['sign_idx'], l:bm['line_nr'], l:new !=# '')
  call s:BookmarkQfReload()
  echo empty(l:new) ? 'Annotation removed' : 'Annotation updated: '. l:new
endfunction

function! s:BookmarkQfDelete() abort
  let l:target = s:BookmarkQfTarget()
  if empty(l:target)
    return
  endif
  let l:bm = l:target.bm
  call bm_sign#del(l:target.file, l:bm['sign_idx'])
  call bm#del_bookmark_at_line(l:target.file, l:bm['line_nr'])
  call s:BookmarkQfReload()
  echo 'Bookmark removed'
endfunction
augroup vimrc_plugins
  autocmd FileType qf call s:BookmarkQfMaps()
augroup END

" ---- indentLine ----
" The guides were drawn all along, but in `Conceal`: 1.65:1 contrast on gruvbox,
" i.e. invisible. Point at a group, not a hex -- indentLine re-reads it on every
" ColorScheme, so this holds for themes installed later. LineNr exists in all 52
" here and averages 5.36:1; 'Comment' (5.94:1) is more prominent.
let g:indentLine_defaultGroup = 'LineNr'

" One matchadd() per indent level, evaluated for every displayed line on every
" redraw. Full redraw at 200x50: 0.96ms at 0 matches, 1.21ms at 8, 1.48ms at 20.
" Kernel style stays well under 8, and sw=8 puts level 8 at column 65.
" Only bites under 3000 lines -- 10- sets b:indentLine_enabled=0 past that.
" g:indentLine_faster / _maxLines are dead code on Vim 9.1.
let g:indentLine_indentLevel = 8

" gruvbox, gruvbox-material and everforest hard-code g:indentLine_color_gui to a
" dim background shade, and an explicit colour beats defaultGroup -- which is why
" the guides were invisible. Unset it after the theme loads. Registered before
" indentLine's own (it loads from after/plugin), so ours runs first.
augroup IndentLineUseGroupColor
  autocmd!
  autocmd ColorScheme * silent! unlet g:indentLine_color_gui
  autocmd ColorScheme * silent! unlet g:indentLine_color_term
augroup END

" Per buffer, not global: the old g:indentLine_setConceal=0 killed the guides
" everywhere for the session once a .tex was opened. b:indentLine_enabled is checked
" before indentLine touches 'conceallevel', so vimtex's conceal setup is still left
" alone -- which was the point of the original line.
augroup vimrc_plugins
  autocmd FileType tex,bib let b:indentLine_enabled = 0
augroup END

" ---- indent guides for TAB-indented files ----
" indentLine draws nothing when 'expandtab' is off: its match pattern ends in a
" literal space (after/plugin/indentLine.vim:179), so it can never match a tab.
" That is every kernel/fbsource file, since vim-sleuth sets noexpandtab there.
" Tabs need 'list'/'listchars' instead. Set window-locally so the global listchars
" in 10-options.vim -- which carries eol:¬ -- is left alone.
" BufWinEnter, not FileType: sleuth has not decided 'expandtab' yet at FileType
" (measured: et=1 there, et=0 by BufWinEnter on the same tab-indented file).
" 'list' is window-local, so it must be actively turned off again or it leaks into
" the next buffer shown in that window; w:vimrc_indent_list means a manual :set
" list is never clobbered.
function! s:IndentGuidesForTabs() abort
  let l:want = &buftype ==# '' && !&expandtab
        \ && get(b:, 'indentLine_enabled', get(g:, 'indentLine_enabled', 1))
  if l:want
    let w:vimrc_indent_list = 1
    setlocal list
    let &l:listchars = 'tab:' . g:indentLine_char . ' '
  elseif get(w:, 'vimrc_indent_list', 0)
    unlet w:vimrc_indent_list
    setlocal nolist
    setlocal listchars<
  endif
endfunction

" 'listchars' paints the tab char with SpecialKey, which gruvbox and friends set to
" the same dim background shade that made the conceal guides invisible (#504945,
" 1.65:1). Point it at the group indentLine uses so both paths match.
" A link, so 40-'s attribute sweep skips it rather than severing it.
function! s:IndentGuideColour() abort
  execute 'highlight! link SpecialKey ' . get(g:, 'indentLine_defaultGroup', 'LineNr')
endfunction

augroup vimrc_indent_guides
  autocmd!
  autocmd BufWinEnter * call s:IndentGuidesForTabs()
  autocmd ColorScheme * call s:IndentGuideColour()
augroup END
call s:IndentGuideColour()
