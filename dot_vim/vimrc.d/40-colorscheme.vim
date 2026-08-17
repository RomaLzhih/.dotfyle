" 40-colorscheme.vim -- theme choice and per-theme highlight normalisation.
" Must precede 50-/60-, whose resolvers read what the theme actually defines.

set background=dark

let g:gruvbox_bold = 0
let g:gruvbox_material_lsp_kind_color = [
      \ ["Variable", "Aqua"],
      \ ]

" ---- no italics, no bold, in any theme ----
" Ask each theme first; only ~half expose an italic option and three a bold one,
" so s:StripUnwantedAttributes() below is the real guarantee. The two
" _disable_italic_comment flags differ because those themes already default
" enable_italic/enable_bold to 0 and only italicise comments.
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
" bold: gruvbox's is set at the top with its other options.
let g:srcery_bold                          = 0
let g:nord_bold                            = 0

augroup nord-theme-overrides
  autocmd!
  autocmd ColorScheme nord highlight Property guifg=#81a1c1
augroup END

" augroup papercolor-theme-overrides
"   autocmd!
"   autocmd ColorScheme PaperColor highlight Function guifg=#d7875f
" augroup END

augroup gruvbox-theme-overrides
  autocmd!
  autocmd ColorScheme gruvbox highlight Property guifg=#83a598
augroup END

" g:airline_theme is pinned in 30-, which skips airline's startup theme probe.
" This restores the one thing that pin removes: following an interactive switch.
augroup AirlineFollowColorscheme
  autocmd!
  autocmd ColorScheme * if v:vim_did_enter && exists('#airline')
        \ | call airline#switch_matching_theme() | endif
augroup END

" ---- flatten TODO/comment slabs: keep the colour, drop the block ----
" Themes disagree on whether TODO/FIXME inside a comment gets a solid slab.
" Normalised here rather than per theme, since <leader>th switches freely.
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

  " With `reverse` the visible slab is the foreground, so keep guifg. Without it
  " the slab IS the background and the foreground only had to read against it --
  " everforest uses its own Normal bg there, which would come out invisible.
  if synIDattr(l:id, 'reverse', 'gui') !=# '1' && !empty(l:guibg)
    let l:normal_bg = synIDattr(synIDtrans(hlID('Normal')), 'bg#', 'gui')
    if !empty(l:normal_bg) && l:guifg ==? l:normal_bg
      let l:guifg   = l:guibg
      let l:ctermfg = synIDattr(l:id, 'bg', 'cterm')
    endif
  endif

  " 'reverse' is dropped: it is the other way a theme fakes a background.
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

let s:text_attributes =
      \ ['bold', 'italic', 'underline', 'undercurl', 'strikethrough', 'reverse', 'standout']

" Sweep every group; rewriting only the attribute lists leaves colours alone.
" LINKED GROUPS MUST BE SKIPPED -- :highlight on a link severs it and blanks the
" group. Skipping suffices: the target is in this same list. See CLAUDE.md.
" One walk, both attributes, flat checks: a sweep per attribute cost 13.3ms and a
" generic [attr, skip] version 43.2ms, versus ~15ms here.
function! s:StripUnwantedAttributes() abort
  for l:group in getcompletion('', 'highlight')
    let l:raw = hlID(l:group)
    let l:id  = synIDtrans(l:raw)
    " l:id != l:raw means this group is a link -- leave it alone.
    if l:id == 0 || l:id != l:raw
      continue
    endif
    let l:it = synIDattr(l:id, 'italic', 'gui') ==# '1'
          \ || synIDattr(l:id, 'italic', 'cterm') ==# '1'
    " airline_* keeps its bold: airline generates those from the theme and keeps
    " bold/non-bold variants on purpose. Drop the test to de-bold the statusline.
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

function! s:FlattenHighlights() abort
  for l:group in g:flat_highlight_groups
    call s:FlattenHighlight(l:group)
  endfor
  call s:StripUnwantedAttributes()
endfunction

" Defined before `colorscheme` below so the startup theme is covered too.
augroup vimrc_flatten_highlights
  autocmd!
  autocmd ColorScheme * call s:FlattenHighlights()
  " Deferred second pass: plugins register their own ColorScheme handlers when they
  " initialise (after the vimrc) and re-add italics, e.g. `hi default CocItalic`.
  " Claiming the group up front fails -- gui=NONE leaves it *cleared*, and
  " `hi default` overrides a cleared group. A 0ms timer runs after everything.
  autocmd ColorScheme * call timer_start(0, {-> s:StripUnwantedAttributes()})
augroup END

set termguicolors
colorscheme gruvbox
" colorscheme solarized8

" kill floaterm when only it and nerdtree remain
function! s:kill_all_floaterm() abort
    for bufnr in floaterm#buflist#gather()
        call floaterm#terminal#kill(bufnr)
    endfor
    return
endfunction
augroup vimrc_colorscheme
  autocmd!
  autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call s:kill_all_floaterm() | quit | endif
  autocmd QuitPre * call s:kill_all_floaterm()
augroup END

" :WQ -- write, drop other unmodified buffers, quit.
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
