" ============================================================================
" 60-coc-semantic.vim
" ----------------------------------------------------------------------------
" Theme-adaptive highlighting for coc's LSP semantic tokens.
" Resolves each token type against whatever the current theme defines.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" ---------------- coc semantic tokens: theme-adaptive highlight resolver ----------------
" coc paints every semantic token with a `CocSemType<Type>` highlight group. Two problems
" this replaces:
"   1. Hardly any colourscheme defines semantic group names, and coc's built-in fallback
"      sends `variable` to `Identifier` -- an accent colour (blue in gruvbox) that is not
"      the theme's plain-text colour, so ordinary locals get recoloured. Measured: in
"      49 of 52 installed themes `Identifier` != `Normal`, while all three themes that do
"      define `Variable` set it equal to `Normal`.
"   2. `:colorscheme` runs `hi clear`, wiping every link, and coc re-applies its own
"      defaults afterwards -- so a one-shot table here silently stops working after the
"      first theme switch.
"
" No theme is named and no colour is hard-coded: each token type is resolved by asking
" the *current* theme what it actually defines, so themes added later adapt on their own.
"
"     theme's own group  ->  treesitter @name  ->  matching standard group  ->  #PLAIN
"
" Speed: the whole resolve is a handful of synID* probes plus ~30 `:hi` commands (~1ms),
" run once per theme change -- never per token, per buffer or per keystroke. Tokens
" themselves are coloured by Vim's native highlight links as it renders, which costs
" nothing extra.
"
" To refine any theme, define the group it lacks *above* this block and it wins, e.g.
"     autocmd ColorScheme mytheme highlight Property guifg=#83a598

let g:coc_default_semantic_highlight_groups = 1
" 1 = italicise parameters so they read apart from locals. Off by default: both use the
" theme's plain-text colour, which is what themes defining `Variable` unanimously chose.
let g:coc_sem_italic_parameters = get(g:, 'coc_sem_italic_parameters', 0)
" How `readonly` (const) tokens should look -- first usable group wins, so it stays
" theme-adaptive. Both candidates exist in every colourscheme tested. Set to [] to
" disable readonly styling entirely.
let g:coc_sem_readonly_chain = get(g:, 'coc_sem_readonly_chain', ['Constant', 'Number'])
" Token types worth styling when `readonly` is set. Kept to the kinds servers actually
" mark const (clangd emits the first four; the rest cover rust-analyzer/gopls) rather
" than all 31, so the resolve stays quick.
let g:coc_sem_readonly_types = get(g:, 'coc_sem_readonly_types',
      \ ['Variable', 'Parameter', 'Property', 'EnumMember', 'Method', 'Function', 'Class', 'Struct'])

" Suffix after `CocSemType` (coc's own capitalisation) -> ordered candidate groups.
" '#PLAIN' means "look like ordinary text" and terminates every chain, so a token can
" never end up invisible or wearing an unrelated accent colour.
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

" True when a group ends up carrying any visible attribute (follows links, checks both
" gui and cterm so cterm-only themes work). synID* primitives only -- no :execute -- and
" memoised per run, because chains share candidates like Type/Constant/Normal.
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

" True when a group's colour differs from ordinary text, i.e. using it would actually be
" visible. Checked in gui and cterm so cterm-only themes are judged on their own terms.
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

" Render as ordinary text: copy Normal's FOREGROUND only, never its background -- a link
" to Normal would paint Normal's bg over CursorLine/Visual/the peek popup's current-line
" highlight and punch holes in them. Setting an explicit attribute (rather than clearing
" the group) is also what stops coc's `hi default link` from putting `Identifier` back:
" `hi default` overrides a cleared group but never one that has settings.
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
  " `readonly` modifier -> colour const-flavoured tokens like constants. coc builds a
  " modifier group from tokenModifiers[0] only, so clangd reports `readonly` first on
  " *uses* of a const symbol; on its declaration line `declaration` comes first and the
  " base colour shows instead. Applied to every token type so servers that mark other
  " kinds readonly (rust-analyzer, gopls) are covered without further changes.
  if !empty(g:coc_sem_readonly_chain)
    let l:ro = ''
    for l:cand in g:coc_sem_readonly_chain
      " Skip a candidate the theme paints the same as ordinary text: it would leave
      " const tokens indistinguishable (nord/quiet/ron colour Constant exactly like
      " Normal). Falls through to the weight-only branch below instead.
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
        " No colour in this theme means "constant", so mark readonly with weight --
        " still theme-agnostic, since it invents no colour of its own.
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

" Colourschemes wipe highlight links, and coc re-applies its defaults on ColorScheme too;
" this augroup is declared after coc is loaded, so it runs last, and the forced links
" above win regardless of ordering.
augroup CocSemThemeAdaptive
  autocmd!
  autocmd ColorScheme * call s:CocSemApply()
augroup END
call s:CocSemApply()

" :SemCheck -- show how every token type resolves under the current theme.
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
