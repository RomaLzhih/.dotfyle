" 60-coc-semantic.vim -- theme-adaptive highlighting for coc's LSP semantic tokens.
"
" coc paints each token with CocSemType<Type>. Few themes define those names, and
" coc's fallback sends `variable` to Identifier -- an accent colour in 49 of 52
" themes here, so plain locals get recoloured. :colorscheme also wipes links and
" coc re-applies its defaults, so a static table stops working after one switch.
"
" Nothing is hard-coded: each type resolves against what the CURRENT theme defines
"     theme's own group -> treesitter @name -> standard group -> #PLAIN
" Runs once per theme change (~1ms), never per token or keystroke.
" To refine a theme, define the group it lacks ABOVE this block and it wins.

let g:coc_default_semantic_highlight_groups = 1
" Italicise parameters. Off: both they and locals use the theme's plain-text colour.
let g:coc_sem_italic_parameters = get(g:, 'coc_sem_italic_parameters', 0)
" How `readonly` (const) tokens look; first usable group wins. [] disables.
let g:coc_sem_readonly_chain = get(g:, 'coc_sem_readonly_chain', ['Constant', 'Number'])
" Only the kinds servers actually mark const, so the resolve stays quick.
let g:coc_sem_readonly_types = get(g:, 'coc_sem_readonly_types',
      \ ['Variable', 'Parameter', 'Property', 'EnumMember', 'Method', 'Function', 'Class', 'Struct'])

" CocSemType suffix -> ordered candidates. '#PLAIN' means "ordinary text" and ends
" every chain, so a token can never be invisible or wear an unrelated accent.
let s:coc_sem_chain = {
      \ 'Variable':      ['Variable', '@variable', '#PLAIN'],
      \ 'Parameter':     ['Parameter', '@variable.parameter', '@parameter', 'Variable', '#PLAIN'],
      \ 'Property':      ['Property', '@property', 'Identifier', '#PLAIN'],
      \ 'EnumMember':    ['EnumMember', '@constant', 'Constant', '#PLAIN'],
      \ 'Namespace':     ['Namespace', '@module', 'Include', 'PreProc', '#PLAIN'],
      \ 'Type':          ['Type', '@type', '#PLAIN'],
      \ 'Class':         ['Class', '@constructor', 'Structure', 'Type', '#PLAIN'],
      \ 'Struct':        ['Struct', '@structure', 'Structure', 'Type', '#PLAIN'],
      \ 'Enum':          ['Enum', 'Structure', 'Type', '#PLAIN'],
      \ 'Interface':     ['Interface', 'Structure', 'Type', '#PLAIN'],
      \ 'TypeParameter': ['TypeParameter', 'Typedef', 'Type', '#PLAIN'],
      \ 'Concept':       ['Concept', 'Typedef', 'Type', '#PLAIN'],
      \ 'BuiltinType':   ['BuiltinType', 'Type', '#PLAIN'],
      \ 'Function':      ['Function', '@function', '#PLAIN'],
      \ 'Method':        ['Method', '@function.method', 'Function', '#PLAIN'],
      \ 'Macro':         ['Macro', '@constant.macro', 'Define', 'PreProc', '#PLAIN'],
      \ 'Keyword':       ['Keyword', '@keyword', 'Statement', '#PLAIN'],
      \ 'SelfKeyword':   ['SelfKeyword', 'Keyword', 'Statement', '#PLAIN'],
      \ 'Modifier':      ['Modifier', '@keyword.storage', 'StorageClass', 'Keyword', '#PLAIN'],
      \ 'Event':         ['Event', 'Keyword', 'Statement', '#PLAIN'],
      \ 'Decorator':     ['Decorator', '@attribute', 'PreProc', '#PLAIN'],
      \ 'Lifetime':      ['Lifetime', 'Special', '#PLAIN'],
      \ 'Label':         ['Label', '#PLAIN'],
      \ 'Comment':       ['Comment', '#PLAIN'],
      \ 'String':        ['String', '@string', '#PLAIN'],
      \ 'Number':        ['Number', '@number', 'Constant', '#PLAIN'],
      \ 'Boolean':       ['Boolean', '@boolean', 'Constant', '#PLAIN'],
      \ 'Regexp':        ['@string.regexp', 'SpecialChar', 'String', '#PLAIN'],
      \ 'Operator':      ['Operator', '@operator', '#PLAIN'],
      \ 'Bracket':       ['#PLAIN'],
      \ 'Unknown':       ['#PLAIN'],
      \ }

" Does this group carry any visible attribute? Follows links, checks gui and cterm.
" synID* only (no :execute) and memoised, since chains share candidates.
function! s:SemUsable(name, cache) abort
  if has_key(a:cache, a:name)
    return a:cache[a:name]
  endif
  let l:ok = 0
  if hlexists(a:name)
    let l:id = synIDtrans(hlID(a:name))
    if l:id != 0
      for l:mode in ['gui', 'cterm']
        if !empty(synIDattr(l:id, 'fg#', l:mode)) || !empty(synIDattr(l:id, 'bg#', l:mode))
          let l:ok = 1
          break
        endif
        for l:attr in ['bold', 'italic', 'underline', 'undercurl', 'reverse', 'standout', 'strikethrough']
          if synIDattr(l:id, l:attr, l:mode) ==# '1'
            let l:ok = 1
            break
          endif
        endfor
        if l:ok
          break
        endif
      endfor
    endif
  endif
  let a:cache[a:name] = l:ok
  return l:ok
endfunction

" Does this group differ from ordinary text, i.e. would using it be visible?
function! s:SemDistinct(name, nfg_gui, nfg_cterm) abort
  let l:id = synIDtrans(hlID(a:name))
  if l:id == 0
    return 0
  endif
  let l:g = synIDattr(l:id, 'fg#', 'gui')
  if !empty(l:g) && (empty(a:nfg_gui) || l:g !=? a:nfg_gui)
    return 1
  endif
  let l:c = synIDattr(l:id, 'fg', 'cterm')
  if !empty(l:c) && (empty(a:nfg_cterm) || l:c !=? a:nfg_cterm)
    return 1
  endif
  return 0
endfunction

" Render as ordinary text: copy Normal's FOREGROUND only. Linking to Normal would
" paint its bg over CursorLine/Visual/the peek popup. Setting an explicit attribute
" (not clearing) is also what stops coc's `hi default link` restoring Identifier --
" `hi default` overrides a cleared group but never one with settings.
function! s:SemPlain(group, fg_gui, fg_cterm) abort
  execute 'hi! link ' . a:group . ' NONE'
  if empty(a:fg_gui) && empty(a:fg_cterm)
    execute 'hi! link ' . a:group . ' Normal'
    return
  endif
  let l:spec = ''
  if !empty(a:fg_gui)
    let l:spec .= ' guifg=' . a:fg_gui
  endif
  if !empty(a:fg_cterm)
    let l:spec .= ' ctermfg=' . a:fg_cterm
  endif
  execute 'hi! ' . a:group . ' term=NONE cterm=NONE gui=NONE' . l:spec
endfunction

function! s:CocSemApply() abort
  if !get(g:, 'coc_default_semantic_highlight_groups', 1)
    return
  endif
  let l:cache = {}
  let l:nid = synIDtrans(hlID('Normal'))
  let l:fg_gui   = l:nid ? synIDattr(l:nid, 'fg#', 'gui')  : ''
  let l:fg_cterm = l:nid ? synIDattr(l:nid, 'fg', 'cterm') : ''
  for [l:suffix, l:chain] in items(s:coc_sem_chain)
    let l:group = 'CocSemType' . l:suffix
    let l:done = 0
    for l:cand in l:chain
      if l:cand ==# '#PLAIN'
        call s:SemPlain(l:group, l:fg_gui, l:fg_cterm)
        let l:done = 1
        break
      elseif s:SemUsable(l:cand, l:cache)
        execute 'hi! link ' . l:group . ' ' . l:cand
        let l:done = 1
        break
      endif
    endfor
    if !l:done
      call s:SemPlain(l:group, l:fg_gui, l:fg_cterm)
    endif
  endfor
  " `readonly` -> colour const-flavoured tokens like constants. coc builds the
  " modifier group from tokenModifiers[0], so clangd only reports readonly on USES
  " of a const symbol; declarations show the base colour. Applied to all listed
  " types so rust-analyzer/gopls are covered too.
  if !empty(g:coc_sem_readonly_chain)
    let l:ro = ''
    for l:cand in g:coc_sem_readonly_chain
      " Skip a candidate painted like ordinary text (nord/quiet/ron do this to
      " Constant); falls through to the weight-only branch below.
      if s:SemUsable(l:cand, l:cache) && s:SemDistinct(l:cand, l:fg_gui, l:fg_cterm)
        let l:ro = l:cand
        break
      endif
    endfor
    for l:suffix in g:coc_sem_readonly_types
      let l:mg = 'CocSemTypeMod' . l:suffix . 'Readonly'
      if !empty(l:ro)
        execute 'hi! link ' . l:mg . ' ' . l:ro
      else
        " No "constant" colour in this theme, so mark readonly with weight instead
        " -- still theme-agnostic, since it invents no colour.
        execute 'hi! link ' . l:mg . ' NONE'
        execute 'hi! ' . l:mg . ' gui=bold cterm=bold'
              \ . (empty(l:fg_gui) ? '' : ' guifg=' . l:fg_gui)
              \ . (empty(l:fg_cterm) ? '' : ' ctermfg=' . l:fg_cterm)
      endif
    endfor
  endif
  if g:coc_sem_italic_parameters
    let l:pid = synIDtrans(hlID('CocSemTypeParameter'))
    let l:pf = l:pid ? synIDattr(l:pid, 'fg#', 'gui') : ''
    let l:pc = l:pid ? synIDattr(l:pid, 'fg', 'cterm') : ''
    execute 'hi! link CocSemTypeParameter NONE'
    execute 'hi! CocSemTypeParameter gui=italic cterm=italic'
          \ . (empty(l:pf) ? '' : ' guifg=' . l:pf)
          \ . (empty(l:pc) ? '' : ' ctermfg=' . l:pc)
  endif
endfunction

" Declared after coc loads so it runs last, and these forced links win.
augroup CocSemThemeAdaptive
  autocmd!
  autocmd ColorScheme * call s:CocSemApply()
augroup END
call s:CocSemApply()

" :SemCheck -- how every token type resolves under the current theme.
function! s:CocSemCheck() abort
  let l:nfg = synIDattr(synIDtrans(hlID('Normal')), 'fg#', 'gui')
  echohl Title
  echo printf('%-24s %-20s %-9s %s', 'GROUP', 'RESOLVES TO', 'FG', 'STATUS')
  echohl None
  for l:suffix in sort(keys(s:coc_sem_chain))
    let l:g = 'CocSemType' . l:suffix
    let l:id = synIDtrans(hlID(l:g))
    let l:fg = l:id ? synIDattr(l:id, 'fg#', 'gui') : ''
    let l:cf = l:id ? synIDattr(l:id, 'fg', 'cterm') : ''
    let l:status = 'coloured'
    if empty(l:fg) && empty(l:cf)
      let l:status = 'no colour'
    elseif !empty(l:nfg) && l:fg ==? l:nfg
      let l:status = 'plain text'
    endif
    echo printf('%-24s %-20s %-9s %s', l:g, synIDattr(l:id, 'name'), l:fg, l:status)
  endfor
endfunction
command! -nargs=0 SemCheck call s:CocSemCheck()
