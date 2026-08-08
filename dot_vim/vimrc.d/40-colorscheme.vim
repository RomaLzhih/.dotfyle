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

