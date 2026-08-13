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

" vim-visual-multi: hand <C-Up>/<C-Down> over to the window-resize maps in
" 20-mappings.vim. VM claims both by default for Add Cursor Up/Down
" (autoload/vm/maps/all.vim:162-163) and it is deferred to SafeState, so it loads
" *after* vimrc.d and overwrites them -- unlike unimpaired, VM does not check
" whether the key is already taken. g:VM_maps is merged over VM's defaults, so
" naming these two moves them and leaves VM's other mappings, <C-n> included, alone.
" nvim is no guide here: multicursors.nvim only binds <C-n> and keeps the rest
" inside its hydra, so <Leader>mj/mk are vim-only (both are free on either side).
let g:VM_maps = {}
let g:VM_maps['Add Cursor Down'] = '<Leader>mj'
let g:VM_maps['Add Cursor Up']   = '<Leader>mk'

" Copilot chat
" nnoremap <C-a> :CopilotChatToggle<CR>
" vnoremap <C-a> <Plug>CopilotChatAddSelection
" let g:copilot_reuse_active_chat = 1

" (Removed: <leader>aa / :ToggleCopilotTerm, a split terminal running the `copilot`
"  CLI, plus its s:ToggleCopilotTerminal(), the g:copilot_term_buf/win globals and the
"  CopilotTerminalSettings augroup. It never worked on this host -- there is no
"  `copilot` executable on PATH -- and with 'term_finish': 'close' the window closed
"  the instant the process failed. The augroup was also testing g:copilot_term_buf on
"  every BufEnter and BufWinEnter for a buffer that could never exist.
"  Inline Copilot ghost text is unaffected: that is copilot.vim, configured below.)

" Copilot cmp
imap <silent><script><expr> <C-e> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = v:true
" copilot#Schedule() (autoload/copilot.vim:412-421) runs on every CursorMovedI and
" arms a timer at `get(g:, 'copilot_idle_delay', 45)`. When it fires, s:VimAttach
" (autoload/copilot/client.vim:239-265) ships a FULL-BUFFER textDocument/didChange --
" the Vim transport has no incremental sync (client.vim:192 is
" join(getbufline(1,'$'))); measured 92KB on kernel/fork.c and 318KB on
" kernel/sched/core.c per trigger.
"
" At 45ms that fires while you are still typing. Measured (pty, real config, fork.c):
" typing one character produced a second redraw burst at ~48ms; at 150 the timer is
" restarted by each keystroke and never fires during continuous typing --
" insert_type ttlb p50 48.6ms -> 8.8ms.
"
" Trade-off: ghost text appears ~105ms later after you stop. 150 rather than 250 keeps
" it usable and stays clear of the CursorHold burst at ~313ms (updatetime=300).
" NOTE: g:copilot_idle_delay is undocumented (not in copilot's doc/ or README) -- it is
" read only at autoload/copilot.vim:418, so re-check it after a copilot update.
let g:copilot_idle_delay = 150

" remove useless auto pairs in cpp and latex
" One augroup per file, so `:source $MYVIMRC` replaces rather than appends.
" `autocmd!` appears ONCE per file, here -- later vimrc_plugins blocks
" must NOT repeat it.
augroup vimrc_plugins
  autocmd!
  autocmd FileType cpp let delimitMate_matchpairs = "(:),[:],{:}"
augroup END

" ---- vim-signature: stop the periodic sign refresh ----
" This was, by a wide margin, the most expensive thing on the idle path. Measured by
" removing each CursorHold handler in turn on an 11336-line kernel file: total 3.15ms,
" of which signature#sign#Refresh() was 2.55ms (context.vim 0.30, devicons 0.13,
" signify/coc/checktime <=0.09 each). It is also completely size-independent -- 2.60ms
" on a 78-line file too -- so this is an every-buffer cost, not a big-file one, and it
" fires on every idle tick (updatetime=300 in 50-coc.vim).
"
" g:SignaturePeriodicRefresh defaults to 1 (signature.vim:34). Turning it off does NOT
" stop marks from getting signs: signature hooks its own m-commands and updates signs
" there. What is lost is the periodic reconciliation, so marks changed by something
" else -- :delmarks, a viminfo restore, another plugin -- can show a stale sign until
" the next signature command. :call signature#sign#Refresh() forces a resync.
let g:SignaturePeriodicRefresh = 0

" ---- vim-devicons: two pure-waste costs, no visible change from either ----
" (1) NERDTree is not installed (see the commented-out Plug line in 00-plugins.vim), but
"     webdevicons registers `autocmd CursorHold * call s:CursorHoldUpdate()`
"     (plugin/webdevicons.vim:399-405) because g:webdevicons_enable_nerdtree defaults to
"     1 (:46). The handler only ever reaches its `!exists('g:NERDTree')` early return at
"     :414. Previously measured at 0.13ms per idle tick. s:set() at :35-43 respects a
"     pre-existing value and s:initialize() runs at :695, i.e. at plugin-load time, which
"     is after vimrc.d -- so setting it here is in time. This also gates off the
"     conceal-brackets FileType augroup at :382-394. Remove the line if NERDTree is ever
"     added back.
let g:webdevicons_enable_nerdtree = 0

" (2) WebDevIconsGetFileTypeSymbol() (plugin/webdevicons.vim:503-549) has no memoisation
"     and is called once per buffer per airline tabline rebuild plus once per statusline
"     redraw -- 741 calls over the 155-keystroke profile, 0.083s self, the highest
"     self-time outside airline itself. Roughly half of each 86us call is the pattern
"     loop at :524, which walks the 9 default regexes in
"     g:WebDevIconsUnicodeDecorateFileNodesPatternSymbols. All 9 are JS-library or
"     Vagrantfile patterns (angular/materialize/jquery/backbone/mootools/require .js,
"     .*vimrc.*, Vagrantfile$) -- none can match a kernel source path, so all 9 run to
"     completion before the extension-dict lookup at :534 succeeds. Measured 86us/call
"     with the patterns, 44us without: ~0.2ms/keystroke at 4.8 calls per key.
"     No icon is lost: .vimrc/.gvimrc/_vimrc are in the exact-match dict
"     (webdevicons.vim:312-314) and 'vim' is in the extension dict (:273).
"     Cleared on VimEnter because s:setDictionaries() (:166, called from s:initialize()
"     at :695) re-merges the defaults into whatever the vimrc set.
augroup vimrc_devicons
  autocmd!
  autocmd VimEnter * ++once let g:WebDevIconsUnicodeDecorateFileNodesPatternSymbols = {}
augroup END

" ---- context.vim: sticky context header (nvim-treesitter-context equivalent) ----
" Enabled by default (g:context_enabled defaults to 1; set here explicitly so it is
" obvious). Presenter is left to auto-detect: it picks 'vim-popup' on any Vim with
" patch-8.1.1364, so the header floats instead of stealing a preview window.
let g:context_enabled = 1
" Keep the header shallow; the default 21 can swallow a third of the window on
" deeply nested code, and 5 lines per indent level is a lot of nesting to show.
let g:context_max_height = 10
let g:context_max_per_indent = 3
" Drop the "<context.vim>" label from the right-hand end of the separator. '<hide>'
" is a sentinel, not a highlight group: settings.vim turns it into show_tag = 0, and
" get_border_line() then emits the border without the tag (and reclaims the width the
" label was using). Use g:context_highlight_border = '<hide>' to drop the whole
" separator line instead.
let g:context_highlight_tag = '<hide>'
" Buffers where a "context" is meaningless -- and where stealing the top lines of
" the window would actively get in the way.
let g:context_filetype_blacklist = ['startify', 'qf', 'coctree', 'floaterm', 'fzf', 'help', 'man']
let g:context_buftype_blacklist  = ['terminal', 'quickfix', 'nofile', 'help']
" NOTE on mappings: context.vim sets g:context_add_mappings=1 by default, but the
" <C-E>/<C-Y>/zz/zb block is gated on `!exists('##WinScrolled')` and Vim 9.1 HAS
" WinScrolled -- so it never runs, and <C-e> stays end-of-line (20-mappings.vim) and
" zz/zb stay vim-smoothie's. It does take zt and H, which nothing here mapped; its
" versions are context-aware (they account for the header height), so that is a win.

" Large-file gate, mirroring the nvim config (lua/plugins/others.lua:224-232 turns
" treesitter-context off past 2000 lines because the header recomputes on
" CursorMoved/WinScrolled and adds scroll jank on big C++). context.vim recomputes on
" the same events, so it needs the same gate. Window-scoped, and only acts on a
" transition so it does not fight a manual :ContextDisableWindow or re-render on
" every BufEnter.
" The previous version of this gate did not work, in two independent ways -- measured,
" not guessed. On kernel/fork.c (3409 lines) a live session showed w:vimrc_context_off=1
" but w:context.enabled=1 and context#util#active()==1, i.e. the header was ON:
"
"  (a) At BufWinEnter for the file named on the command line, w:context does not exist
"      yet, so :ContextDisableWindow -> context#disable(0) -> s:set_enabled does
"      `let c = getwinvar(win_getid(winnr), 'context', {})` (autoload/context.vim:166)
"      and writes enabled=0 into a throwaway dict. Then plugin/context.vim:49's
"      `VimEnter * ContextActivate` does `unlet! w:context` (autoload/context.vim:10)
"      and rebuilds it with enabled = g:context.enabled = 1. Because the old gate only
"      acted on a transition, and had already set w:vimrc_context_off=1, it never retried.
"
"  (b) Even a working :ContextDisableWindow does not stop the work. context#update()
"      calls context#util#update_state() at autoload/context.vim:99 -- BEFORE the
"      !context#util#active() test at :113 -- and update_state toggles 'conceallevel'
"      (autoload/context/util.vim:118-121). 'conceallevel' is a redraw-window option, so
"      every cursor move invalidated the window and forced a full syntax re-highlight,
"      even with the header disabled and even though conceallevel was already 0. That
"      cost is invisible to :profile (the profiler times the vimscript, not the redraw
"      the option-set schedules), which is why context#update looked minor at 0.09s/148.
"
" So: take over the event registration instead of disabling after the fact.
" g:context_add_autocmds is read by context#settings#parse() (settings.vim:29) and gates
" the entire `augroup context.vim` at plugin/context.vim:46-63, including its
" `VimEnter * ContextActivate` -- hence the explicit ContextActivate below. vimrc.d is
" sourced before plugin/**, so setting it here is in time.
"
" Measured, cursor move + redraw at 200x50 on fork.c: 1.83ms before, 0.19ms after
" (0.064ms with the handler skipped entirely). On a 10k-line driver the avoided forced
" redraw alone is ~4.4ms. context.vim still works normally on files under the limit.
let g:context_size_limit = 2000
let g:context_add_autocmds = 0

function! s:ContextSizeGate() abort
  let l:big = line('$') > g:context_size_limit
  let w:vimrc_context_off = l:big
  if !exists(':ContextEnableWindow')
    return
  endif
  " Read the real state out of w:context rather than tracking our own transition flag,
  " so a window that context.vim re-initialised is noticed. -1 == not initialised yet.
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
  " ContextActivate is normally plugin/context.vim:49's VimEnter; with
  " g:context_add_autocmds=0 that augroup never exists, so do it here -- and re-apply
  " the gate afterwards, since activation rebuilds w:context with enabled=1.
  autocmd VimEnter * call s:ContextSizeGate()
        \ | ContextActivate
        \ | if get(w:, 'vimrc_context_off', 0) | ContextDisableWindow | endif
  " Same event list as plugin/context.vim:50-62, each behind the size gate.
  " (Its `User GitGutter` entry is dropped: vim-gitgutter is not installed.)
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

" cool total match count
" DELIBERATELY 0. vim-cool does not use searchcount(): with this on, s:StartHL walks
" the whole buffer with `silent exe "keepjumps norm! n"` in a loop, once per match
" (vim-cool/plugin/cool.vim:59-78), then forces a full `redraw` at :79. That autocmd is
" registered permanently at load (cool.vim:139, because 'hlsearch' is set above), so it
" runs on every CursorMoved while the cursor sits on a match -- i.e. on every /, n, N.
" Measured on kernel/fork.c: 0.56ms for /copy_process, 4.42ms for /task (315 matches),
" 6.22ms for /struct (465), plus ~0.9ms for the forced redraw. It also gives up
" silently past 100ms (cool.vim:63-66), so the number was already unreliable on big
" files. airline's searchcount extension already shows the same count in section y
" (autoload/airline/extensions/searchcount.vim:16-17), so this was paying twice.
" What is lost: vim-cool's command-line echo. Its actual job -- auto-:nohlsearch once
" you move off the match -- is unaffected by this flag.
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
" Tabline entries read "<filetype icon> parent/file.c" -- enough context to tell
" apart the same filename in different directories without the abbreviated
" /b/a/d/ prefix the default formatter produces. Implemented in
" ~/.vim/autoload/airline/extensions/tabline/formatters/parentfile.vim (airline
" resolves formatters by autoload path, so it cannot live in this file).
" Devicons' own airline hook is switched off because it appends the glyph after
" the name and would swap its formatter in for this one; parentfile.vim calls
" WebDevIconsGetFileTypeSymbol() itself, once per buffer, exactly as the devicons
" wrapper did -- so no extra cost over the previous setup.
let g:airline#extensions#tabline#formatter = 'parentfile'
let g:webdevicons_enable_airline_tabline = 0
" Renders identically at 0 -- this is purely to stop work.
" buffers#get() calls s:map_keys() as its FIRST action (buffers.vim:55), four lines
" BEFORE its own s:current_tabline cache check at :59. s:map_keys reads
" `get(g:, 'airline#extensions#tabline#buffer_idx_mode', 1)` at :210 -- default 1 --
" which is inconsistent with the default 0 used by the RENDER paths at :134 and :177.
" So with the variable unset, 14 `<Plug>AirlineSelectTab*` :noremap commands are
" re-executed on every tabline redraw (~1.6/keystroke): 3458 mapping-table writes over
" the 155-keystroke profile, 0.073s self time -- the highest in the whole tabline chain.
" Measured directly in `vim -u NONE`: 14.5ms real for 247 x 14 noremap.
" At 0, s:map_keys returns at :211. Nothing is lost: grep finds no AirlineSelect
" reference anywhere in ~/.vim/vimrc.d or ~/.vimrc (which matters, since a <Plug> RHS
" is live even under nnoremap on Vim 9.1).
let g:airline#extensions#tabline#buffer_idx_mode = 0
" DELIBERATELY NOT SET: g:airline_skip_empty_sections (default 0, builder.vim:193).
" With it on, s:section_is_empty() extracts every %{...} in a section
" (builder.vim:215) and eval()s each one (:217-225) on every build, on TOP of the
" redraw-time evaluation. It does not hit every section -- the greedy strip at :207-208
" leaves any literal text outside the first '%{' .. last '}' span, so g:airline_section_c
" below keeps '%<' and '%m' and is exempt, as are inactive windows and the tabline
" (:186-189). What it would double is the pure-%{} sections, i.e. section b
" (hunks#get_hunks + branch#get_head) -- exactly the chain that is already expensive.
let g:airline_left_sep='>'
let g:airline#extensions#whitespace#enabled = 0
" (Removed: `au VimEnter * let [g:airline_section_y] = [airline#section#create([''])]`.
"  It was a no-op -- airline#section#create(['']) returns '', and vim-devicons
"  overwrites the WINDOW-local w:airline_section_y on every rebuild, which beats
"  the global. Section y renders identically without it. To actually blank that
"  slot, set g:webdevicons_enable_airline_statusline_fileformat_symbols = 0.)

" --- section c: path relative to the project root, not the full path ---
" airline's default 'file' part is literally `%f`, which Vim renders relative to
" the CWD -- so it goes absolute as soon as you open something outside it (fzf
" from another dir, :e on an absolute path, a startify recent entry). This config
" deliberately never auto-cds (g:startify_change_to_dir = 0), so that happens a lot.
"
" airline ships `g:airline_stl_path_style = 'gitrepo'` for this, but it goes
" through FugitiveFind, so it is git-only and falls back to the FULL path
" otherwise -- no good here, since fbsource is a Sapling checkout (.hg) and
" fugitive has zero Sapling support. Hence the marker walk below, which covers
" .git (kernel, below, dotfiles), .hg (fbsource/Sapling) and .sl.
"
" Set as a raw string rather than airline#section#create() so nothing forces
" airline's autoload to load during startup. It mirrors airline's own default
" section c -- ['%<', 'file', ' ', 'readonly', 'coc_status'] -- so if you ever
" want the stock layout back, just delete this and the two functions.
let g:airline_section_c = '%<%{AirlineProjectPath()}%m '
      \ . '%{airline#util#wrap(airline#parts#readonly(),0)}'
      \ . '%{airline#util#wrap(airline#extensions#coc#get_status(),0)}'

" Deepest marker wins, so a git checkout nested inside an hg repo resolves to the
" inner one. Each miss is a full walk to /, which is why the result is cached per
" buffer -- this runs on every statusline redraw.
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
  " terminals, quickfix, coctree, help: a project path is meaningless
  if &buftype !=# '' && &buftype !=# 'help'
    return expand('%:t')
  endif
  let l:full = expand('%:p')
  if get(b:, 'airline_pp_src', '') ==# l:full && exists('b:airline_pp')
    return b:airline_pp
  endif
  " Compare RESOLVED paths on both sides. fnamemodify(':p') resolves symlinks but
  " expand('%:p') does not, so the two disagree whenever the tree is reached via a
  " link -- ~/fbsource -> ~/local/fbsource -> /data/users/zmen/fbsource being the
  " case here. Without this the prefix test fails and every fbsource file silently
  " falls back to the cwd-relative path.
  let l:root = s:AirlineProjectRoot(l:full)
  let l:rfull = resolve(l:full)
  let l:rroot = empty(l:root) ? '' : resolve(l:root)
  if !empty(l:rroot) && l:rfull[: len(l:rroot) - 1] ==# l:rroot
    let b:airline_pp = l:rfull[len(l:rroot) + 1 :]
  else
    " no VCS root, or file outside it: fall back to cwd-relative, i.e. what %f did
    let b:airline_pp = fnamemodify(l:full, ':.')
  endif
  let b:airline_pp_src = l:full
  return b:airline_pp
endfunction

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
" Recent files in this project. nvim has this on <A-w> (Telescope frecency
" workspace=CWD), but Alt keys do not reach this terminal Vim -- verified: a
" mapped <A-w> pressed in tmux never fires -- so it lives on <Leader>fr here.
" fzf#vim#_recent_files() formats every entry with ':~:.', so anything under the
" cwd comes back RELATIVE while anything outside starts with '/' or '~'. Filtering
" on that leading character IS the cwd scope, with no extra path arithmetic.
" (fzf.vim's own :History is still there, unmapped, for the global list.)
command! -bang HistoryCwd call fzf#run(fzf#wrap('historycwd', {
      \ 'source':  filter(fzf#vim#_recent_files(), 'v:val !~# "^[~/]"'),
      \ 'options': ['--prompt', 'RecentHere> '],
      \ }, <bang>0))
nnoremap <Leader>fr :HistoryCwd<CR>
" Browse the : command-line history in fzf. <CR> runs the selected command,
" <C-e> puts it on the command line to edit first -- both are fzf.vim's own
" behaviour (autoload/fzf/vim.vim, s:history_sink), which also re-histadd()s the
" entry so it stays at the top of the list. No wrapper needed: ':History:' with
" the trailing colon is dispatched to fzf#vim#command_history() by
" fzf.vim/plugin/fzf.vim:83. ':History/' is the same thing for search history.
" <Leader>: is LazyVim's key for this across all three of its picker backends, so
" it matches if the nvim side ever gains one -- lazyvim.json currently has
" extras: [], so nvim has no command-history picker bound at the moment.
nnoremap <Leader>: :History:<CR>
nnoremap <Leader>fj :Jumps<CR>
" Moved off <Leader>fm, which is now :Format in 50-coc.vim (k = marK).
nnoremap <Leader>fk :Marks<CR>

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

" In the bookmark list (opened by <Leader>hh), the entry under the cursor can be
" edited without jumping to it: 1-9 jump to that slot, `i` edits the annotation,
" `dd` deletes the bookmark, `K`/`J` move it up/down the list.
" Scoped by the qf title so count-prefixed motions still work in other quickfix
" lists (grep, errors, etc.); the maps are cleared when the same qf buffer is
" reused for a non-bookmark list.
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
    " <Plug>BookmarkShowAll has just filled the list in positional order; put it
    " back into the user's order before the window is drawn.
    call s:BookmarkQfRender()
  else
    for l:key in ['i', 'dd', 'K', 'J']
      silent! execute 'nunmap <buffer> ' . l:key
    endfor
  endif
endfunction

" --- ordering ---------------------------------------------------------------
" vim-bookmarks has no notion of order: bm#location_list() re-derives it every
" time from (file path, line number), and bm#serialize() only ever writes
" sign_idx/line_nr/content/annotation, so an extra field on a bookmark would be
" dropped on the next save -- which happens constantly, since the plugin also
" reloads from disk on every BufEnter. The order therefore lives in a side file
" next to the per-project bookmark file, holding sign_idx values: the one
" bookmark attribute that is both stable while you edit a file and round-tripped
" by the plugin's own save format.
" The file is advisory. Bookmarks missing from it (newly added ones) sort last
" in the plugin's positional order, and entries whose bookmark is gone are
" dropped, so deleting the file just restores plain positional order.
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
  " Never persist an empty order. vim-bookmarks drops and reloads its whole
  " model on every BufEnter, so a render that catches it mid-reload -- or in a
  " directory whose bookmarks have not loaded yet -- would otherwise truncate
  " the file and lose the ordering for good. There is nothing to record anyway,
  " and stale sign_idx values in the file are ignored on read.
  if empty(a:sign_idxs) || s:BookmarkOrderGet() ==# a:sign_idxs
    return
  endif
  let s:bookmark_order = copy(a:sign_idxs)
  call writefile(map(copy(a:sign_idxs), 'string(v:val)'), s:BookmarkOrderFile())
endfunction

" Every bookmark as {'file', 'bm', 'idx'}, in display order: the saved order
" first, then anything it does not mention, in the plugin's positional order.
" 'idx' is str2nr()'d because the plugin's own s:refresh_line_numbers() rebuilds
" bookmarks from keys(), turning sign_idx into a string on any file you have
" visited -- writing those verbatim would persist quoted junk that reads back
" as 0 and silently drops the bookmark's slot on the next session.
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

" Rewrite the list in place, keeping the same qf list and title so the 1-9 maps
" and the bookmark-list detection keep working.
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

" Re-render after a change and persist. The explicit save matters: vim-bookmarks
" only auto-saves on BufLeave/VimLeave but reloads from disk on every BufEnter,
" so an edit made from a quickfix window -- which you can leave without ever
" triggering BufLeave on a bookmarked file -- would otherwise be thrown away.
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
  " In the console inputdialog() returns the pre-filled text on <Esc>, so an
  " escape lands on the ==# l:old no-op below; C-u then <CR> clears the note.
  let l:new = inputdialog((empty(l:old) ? 'Enter' : 'Edit') .' annotation: ', l:old)
  redraw!
  if l:new ==# l:old
    return
  endif
  call bm#update_annotation(l:target.file, l:bm['sign_idx'], l:new)
  " Annotated bookmarks use a different sign glyph, so re-place the sign.
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

" NOTE: indentLine
" The guides were being drawn all along, but in the `Conceal` colour: #504945 on
" gruvbox's #282828 background is a 1.65:1 contrast ratio, i.e. invisible. Point it
" at a highlight group instead of a hex colour -- indentLine re-reads the group on
" every ColorScheme/Syntax event, so this stays correct in any theme, including ones
" installed later. LineNr is defined in all 52 themes here and averages 5.36:1.
" Swap in 'Comment' (5.94:1 mean) if you want the guides more prominent.
let g:indentLine_defaultGroup = 'LineNr'

" indentLine draws the guides with matchadd('Conceal', '^\s\+\zs\%<N>v ') -- one match
" per indent level (after/plugin/indentLine.vim:172-180), every one of which is
" evaluated for every displayed line on every redraw. The default
" g:indentLine_indentLevel is 20. Measured, forced full redraw at 200x50 on a C file:
" 0.96ms with 0 matches, 1.21ms with 8, 1.48ms with 20 -- so the default costs ~0.5ms
" per full redraw and 8 costs ~0.25ms. Kernel style keeps nesting well under 8 levels,
" and vim-sleuth sets sw=8 on kernel C, so level 8 already reaches column 65.
" This only bites on files UNDER 3000 lines: 10-options.vim sets b:indentLine_enabled=0
" past that.
" Do NOT bother with g:indentLine_faster or g:indentLine_maxLines: after/plugin/
" indentLine.vim:18 sets g:indentLine_newVersion=1 on any Vim > 7.4.792, and both are
" only read in the newVersion==0 branch at :199/:204. They are dead code on Vim 9.1.
let g:indentLine_indentLevel = 8

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

