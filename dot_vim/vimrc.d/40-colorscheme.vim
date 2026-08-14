" ============================================================================
" 40-colorscheme.vim
" ----------------------------------------------------------------------------
" Theme selection plus per-theme highlight overrides. Any override
" defined here is picked up by the resolvers in 50-/60-, so it must
" be sourced before them.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" -----------------------------------COLOR SCHEME-----------------------------------
"  set highlight color
set background=dark

" Color scheme (terminal)
" gruvbox-material
let g:gruvbox_bold = 0
let g:gruvbox_material_lsp_kind_color = [
      \ ["Variable", "Aqua"],
      \ ]

" ---- no italics and no bold, in any theme ----
" Ask each theme not to emit them in the first place. Only about half the installed
" themes expose an italic option and only three expose a bold one, so
" s:StripUnwantedAttributes() below is the actual guarantee -- these just keep the sweep from
" having to undo work, and stop a theme re-applying them from its own autocmds.
" Names verified against each plugin's source; the two `_disable_italic_comment`
" flags are the odd ones out because gruvbox-material and everforest already
" default `enable_italic` to 0 and italicise only comments. gruvbox-material's
" `enable_bold` likewise already defaults to 0, so it needs no entry.
let g:srcery_italic                        = 0
let g:gruvbox_italic                       = 0
let g:gruvbox_italicize_comments           = 0
let g:gruvbox_italicize_strings            = 0
let g:gruvbox_material_disable_italic_comment = 1
let g:everforest_disable_italic_comment    = 1
let g:nord_italic                          = 0
let g:nord_italic_comments                 = 0
let g:jellybeans_use_gui_italics           = 0
let g:jellybeans_use_term_italics          = 0
let g:moonflyItalics                       = 0
let g:codedark_italics                     = 0
let g:tender_italic                        = 0
" bold: gruvbox's is already set to 0 further up, next to the other gruvbox options
let g:srcery_bold                          = 0
let g:nord_bold                            = 0
" nord
augroup nord-theme-overrides
  autocmd!
  autocmd ColorScheme nord highlight Property guifg=#81a1c1
augroup END

" paper color 
" augroup papercolor-theme-overrides
"   autocmd!
"   autocmd ColorScheme PaperColor highlight Function guifg=#d7875f
" augroup END

" gruvbox
augroup gruvbox-theme-overrides
  autocmd!
  autocmd ColorScheme gruvbox highlight Property guifg=#83a598
augroup END

" g:airline_theme is pinned in 30-plugin-config.vim so airline skips its startup
" theme probe. Restore the one runtime behaviour that pin removes: following the
" colourscheme when one is picked interactively (<leader>th). Both guards are
" false during startup -- v:vim_did_enter is 0, and airline's own plugin file has
" not been sourced yet -- so `colorscheme gruvbox` below costs nothing here.
augroup AirlineFollowColorscheme
  autocmd!
  autocmd ColorScheme * if v:vim_did_enter && exists('#airline')
        \ | call airline#switch_matching_theme() | endif
augroup END

" ---- flatten comment-ish groups: keep the theme's colour, drop the block ----
" Themes disagree about whether the TODO/FIXME/XXX/NOTE keywords inside a comment
" get a solid slab of colour behind them. gruvbox-material paints one teal via
" `gui=bold,reverse guifg=#7daea3 guibg=#282828` (reverse swaps those, so guibg
" reads as the normal background while the screen shows teal); everforest sets
" guibg=#7fbbb3 outright; gruvbox and srcery leave it flat. Since <leader>th
" switches themes freely, normalise it instead of patching each theme.
"
" Keeps the foreground and every text attribute the theme picked -- only the
" background and `reverse` go, so a reversed group collapses to coloured text on
" the normal background rather than losing its colour entirely.
let g:flat_highlight_groups = ['Comment', 'SpecialComment', 'Todo']

function! s:FlattenHighlight(group) abort
  let l:id = hlID(a:group)
  if !l:id
    return
  endif
  let l:id = synIDtrans(l:id)
  let l:guifg   = synIDattr(l:id, 'fg#', 'gui')
  let l:ctermfg = synIDattr(l:id, 'fg', 'cterm')
  let l:guibg   = synIDattr(l:id, 'bg#', 'gui')

  " Which colour survives depends on how the theme built the block.
  " With `reverse` (gruvbox-material) the visible slab is the *foreground*, so
  " keeping guifg is right. Without it the slab IS the background, and the
  " foreground was only ever chosen to read against that slab -- everforest uses
  " its own Normal background for it (#2d353b text on #2d353b once the block is
  " gone, i.e. invisible). There, promote the background to the foreground.
  if synIDattr(l:id, 'reverse', 'gui') !=# '1' && !empty(l:guibg)
    let l:normal_bg = synIDattr(synIDtrans(hlID('Normal')), 'bg#', 'gui')
    if !empty(l:normal_bg) && l:guifg ==? l:normal_bg
      let l:guifg   = l:guibg
      let l:ctermfg = synIDattr(l:id, 'bg', 'cterm')
    endif
  endif

  " 'reverse' is dropped deliberately; it is the other way a theme fakes a
  " background. 'inverse' is just Vim's alias for it, so it needs no entry.
  let l:attrs = filter(['bold', 'italic', 'underline', 'undercurl', 'strikethrough'],
        \ 'synIDattr(l:id, v:val, "gui") ==# "1"')
  let l:cmd = 'highlight ' . a:group . ' guibg=NONE ctermbg=NONE'
        \ . ' gui='   . (empty(l:attrs) ? 'NONE' : join(l:attrs, ','))
        \ . ' cterm=' . (empty(l:attrs) ? 'NONE' : join(l:attrs, ','))
  if !empty(l:guifg)
    let l:cmd .= ' guifg=' . l:guifg
  endif
  if !empty(l:ctermfg)
    let l:cmd .= ' ctermfg=' . l:ctermfg
  endif
  execute l:cmd
endfunction

" solarized8, PaperColor, catppuccin, rose-pine, monokai, hybrid, night-owl,
" aquarium and darcula expose no italic option at all, and gruvbox-material and
" everforest only cover comments, so the options above cannot be the whole answer.
" Sweep every group after the theme has loaded.
" Rewrites the attribute lists only: `:highlight {group} gui=... cterm=...` leaves
" guifg/guibg/guisp untouched, so colours survive.
"
" Linked groups MUST be skipped rather than rewritten. synIDtrans() resolves a link
" to its target, so a group linked to a bold one reports bold here -- but running
" :highlight on it SEVERS the link and leaves a standalone group with no colours at
" all, which then falls back to Normal. koehler is the case that exposed this: it
" does `hi! link Conditional Statement` (also Repeat/Keyword/Label/Operator/
" Exception) over a bold Statement, so `if` and `while` rendered white.
" Skipping is sufficient, not merely safe: the link target is itself in this list and
" gets stripped on its own, after which the link inherits the result.
let s:text_attributes =
      \ ['bold', 'italic', 'underline', 'undercurl', 'strikethrough', 'reverse', 'standout']

" One walk, both attributes, no per-group list building. Two earlier shapes were
" measured and are slower on ~700 groups: a separate full sweep per attribute cost
" 13.3ms (it repeats getcompletion() and the whole walk), and a generic version
" taking a list of [attribute, skip] pairs cost 43.2ms -- in Vimscript the per-group
" list unpacking and allocation swamped the walk it saved. Hence the flat, hardcoded
" pair of checks below.
function! s:StripUnwantedAttributes() abort
  for l:group in getcompletion('', 'highlight')
    let l:raw = hlID(l:group)
    let l:id  = synIDtrans(l:raw)
    " l:id != l:raw means this group is a link -- leave it alone, see above.
    if l:id == 0 || l:id != l:raw
      continue
    endif
    let l:it = synIDattr(l:id, 'italic', 'gui') ==# '1'
          \ || synIDattr(l:id, 'italic', 'cterm') ==# '1'
    " airline_* keeps its bold: those groups are generated by airline from the
    " theme, not by the theme, and it maintains a bold and a non-bold variant of
    " each section deliberately. Airline also rebuilds them from its own
    " ColorScheme handler after the sync pass, so stripping them here would only
    " flatten the statusline on the deferred pass. Delete the `l:group !~#` test
    " if you want the statusline de-bolded too.
    let l:bo = l:group !~# '^airline_'
          \ && (synIDattr(l:id, 'bold', 'gui') ==# '1'
          \     || synIDattr(l:id, 'bold', 'cterm') ==# '1')
    if !l:it && !l:bo
      continue
    endif
    let l:spec = ''
    for l:mode in ['gui', 'cterm']
      let l:attrs = filter(copy(s:text_attributes),
            \ '!(v:val ==# "italic" && l:it) && !(v:val ==# "bold" && l:bo)'
            \ . ' && synIDattr(l:id, v:val, l:mode) ==# "1"')
      let l:spec .= ' ' . l:mode . '=' . (empty(l:attrs) ? 'NONE' : join(l:attrs, ','))
    endfor
    execute 'highlight' l:group . l:spec
  endfor
endfunction

" Both attributes, in every theme. The options above cover only some of them:
" vim-colors-xcode, for instance, hardcodes `gui=bold cterm=bold` on Statement,
" Title and Todo in all seven variants (colors/xcodedark.vim:97,103,104 plus the
" cterm block at :409-416) and has no bold option at all -- its emph_types/
" emph_funcs/emph_idents settings only pick which of types/functions/identifiers
" gets the accent colour, and set gui=NONE in both branches.
function! s:FlattenHighlights() abort
  for l:group in g:flat_highlight_groups
    call s:FlattenHighlight(l:group)
  endfor
  call s:StripUnwantedAttributes()
endfunction

" Must be defined before the `colorscheme` below so the startup theme is covered
" too, not just later <leader>th switches.
augroup vimrc_flatten_highlights
  autocmd!
  autocmd ColorScheme * call s:FlattenHighlights()
  " Second, deferred pass. Plugins install their own ColorScheme handlers when they
  " initialise -- coc creates that augroup at attach time, i.e. after the vimrc -- so
  " theirs runs after the sync pass above and puts italics back:
  " `hi default CocItalic ... gui=italic` at plugin/coc.vim:460. The same applies at
  " startup, where plugin/ files are sourced after the vimrc's `colorscheme` command.
  " Claiming the group up front does not work: `hi CocItalic gui=NONE` leaves it
  " *cleared*, and `hi default` does override a cleared group.
  " A 0ms timer fires once the whole event chain and plugin loading have finished,
  " which is the only point where every group definitely exists.
  autocmd ColorScheme * call timer_start(0, {-> s:StripUnwantedAttributes()})
augroup END

set termguicolors
colorscheme gruvbox
" colorscheme solarized8

" kill both floaterm and nerdtree when only they exists
function! s:kill_all_floaterm() abort
    for bufnr in floaterm#buflist#gather()
        call floaterm#terminal#kill(bufnr)
    endfor
    return
endfunction
" (Dropped a third autocmd here: its guard was this BufEnter's guard AND
"  `tabpagenr('$') == 1`, with a byte-identical body, so it could never fire in a
"  case the line below does not already cover.)
augroup vimrc_colorscheme
  autocmd!
  autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call s:kill_all_floaterm() | quit | endif
  autocmd QuitPre * call s:kill_all_floaterm()
augroup END

" kill all buffers when writing wq
function! SaveAndQuit()
  write
  let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  for buf in buffers
    if !getbufvar(buf, '&modified') && buf != bufnr('%')
      execute 'bdelete' buf
    endif
  endfor
  quit
endfunction
command! WQ call SaveAndQuit()
