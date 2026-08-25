" 55-textobjects.vim -- structural text objects and function motions.
"
" Mirrors what nvim ACTUALLY provides, which is not what its config appears to say.
" The `textobjects = {...}` block in ~/.config/nvim/lua/plugins/treesitter.lua is
" dead: it sits in the opts of the nvim-treesitter spec, and that plugin's setup()
" reads only `install_dir`. Nothing reads opts.textobjects. The live objects over
" there come from LazyVim's mini.ai (lazyvim/plugins/coding.lua):
"
"     af/if = @function    ac/ic = @class    aa/ia = argument
"     ao/io = @block / @conditional / @loop   ("code block", nearest of the three)
"
" So ac/ic = class in 50-coc.vim ALREADY mirrors nvim, and `al`/`il` -- the obvious
" guess for a loop object -- exists in neither editor. Do not add it: targets.vim
" maps only the bare `i`/`a` as <expr> and reads the following keys itself, so `l`
" is its "last" modifier. Binding `il` makes `il` a complete match and kills the
" whole il( / al) / ilt / ila family. `ao`/`io` are free of targets' triggers and
" modifiers and of every Vim builtin, and they are what nvim uses anyway.
"
" Sourced after 50-coc.vim on purpose: the af/if/ac/ic guards at the bottom re-map
" keys that 50- binds directly to coc's <Plug>s.

" ---- ao / io : block / conditional / loop -----------------------------------
" There is no treesitter in Vim 9.1, but clangd answers textDocument/selectionRange
" with the AST ancestry of the cursor, and that chain contains the enclosing block,
" conditional and loop as exact ranges -- both outer and inner. coc exposes it as
" CocAction('selectionRanges'). Measured at 3.1ms on a kernel .c, i.e. cheaper than
" the documentSymbols round-trip that af/if already pay.
"
" This is NOT the documentSymbol path used by coc's funcobj/classobj: SymbolKind has
" no loop or conditional, so selectSymbolRange can never produce these.

" `switch` is a deliberate divergence: tree-sitter's C queries capture no
" switch_statement at all, so upstream `ao` on a switch falls back to its {...}
" body. Treating it as a construct selects the whole statement, which is more useful
" and costs nothing.
let s:construct = '^\%(if\|else\|for\|while\|do\|switch\)\>'

function! s:CocReady() abort
  " Cheap and RPC-free. CocAction() itself throws when this is 0, which is exactly
  " what makes af/if blow up in buffers with no language server.
  return exists('*CocAction') && get(g:, 'coc_service_initialized', 0)
endfunction

" Ranges enclosing the cursor, innermost first. LSP positions: 0-based lines,
" 0-based character, end exclusive.
function! s:Chain() abort
  if !s:CocReady()
    return []
  endif
  try
    let l:sr = CocAction('selectionRanges')
  catch
    return []
  endtry
  if type(l:sr) != v:t_list || empty(l:sr)
    return []
  endif
  let l:out = []
  let l:node = l:sr[0]
  while type(l:node) == v:t_dict && has_key(l:node, 'range')
    call add(l:out, l:node.range)
    if !has_key(l:node, 'parent')
      break
    endif
    let l:node = l:node.parent
  endwhile
  return l:out
endfunction

" Selections are {'rg': <LSP range>, 'lw': 0|1}. The linewise flag matters: Vim's
" own i{ is LINEWISE when the braces sit on their own lines, while a{ is charwise
" (measured, not assumed). Matching that is what makes `dio` remove a body cleanly
" instead of leaving a blank line behind. nvim's mini.ai is charwise for both; this
" is a deliberate divergence in favour of existing Vim muscle memory.

" Interior of a delimited range.
function! s:Inset(rg) abort
  let l:sl = a:rg.start.line
  let l:el = a:rg.end.line
  if l:el > l:sl + 1
    " l:el is 0-based, so getline(l:el) is the LAST interior line (1-based).
    return {'lw': 1,
          \ 'rg': {'start': {'line': l:sl + 1, 'character': 0},
          \        'end':   {'line': l:el - 1, 'character': len(getline(l:el))}}}
  endif
  return {'lw': 0,
        \ 'rg': {'start': {'line': l:sl, 'character': a:rg.start.character + 1},
        \        'end':   {'line': l:el, 'character': max([0, a:rg.end.character - 1])}}}
endfunction

function! s:Construct(inner) abort
  let l:chain = s:Chain()
  let l:i = 0
  while l:i < len(l:chain)
    let l:rg = l:chain[l:i]
    let l:text = strpart(getline(l:rg.start.line + 1), l:rg.start.character)
    " @block.outer -- a compound statement, so the range opens on its `{`.
    if l:text[0] ==# '{'
      return a:inner ? s:Inset(l:rg) : {'lw': 0, 'rg': l:rg}
    endif
    " @conditional.outer / @loop.outer -- the range opens on the keyword.
    if l:text =~# s:construct
      if !a:inner
        return {'lw': 0, 'rg': l:rg}
      endif
      " The body is the next range inward whenever the cursor is inside it; only a
      " cursor in the header (the parenthesised condition) has nothing smaller.
      " clangd reports that body INCLUDING its braces, so it needs insetting too.
      if l:i > 0
        let l:body = l:chain[l:i - 1]
        let l:btxt = strpart(getline(l:body.start.line + 1), l:body.start.character)
        return l:btxt[0] ==# '{' ? s:Inset(l:body) : {'lw': 0, 'rg': l:body}
      endif
      return s:Inset(l:rg)
    endif
    let l:i += 1
  endwhile
  return {}
endfunction

" The enclosing {...}, for buffers with no language server. Bounded with a timeout:
" an unbounded searchpair on a 30k-line file measured 841ms. No skip expression --
" the usual synID 'comment\|string' idiom is unreliable here (a `case '{':` char
" literal reports cCharacter, and 10- sets synmaxcol=200 on big files) and costs
" ~50x a plain search step.
function! s:BraceBlock(inner) abort
  let l:open = getline('.')[col('.') - 1] ==# '{'
        \ ? [line('.'), col('.')]
        \ : searchpairpos('{', '', '}', 'bnW', '', 0, 100)
  if l:open == [0, 0]
    return {}
  endif
  let l:save = getcurpos()
  call cursor(l:open[0], l:open[1])
  let l:close = searchpairpos('{', '', '}', 'nW', '', 0, 100)
  call setpos('.', l:save)
  if l:close == [0, 0]
    return {}
  endif
  " Rebuilt in LSP shape (0-based, end exclusive) so one selector serves both paths.
  let l:rg = {'start': {'line': l:open[0] - 1,  'character': l:open[1] - 1},
        \     'end':   {'line': l:close[0] - 1, 'character': l:close[1]}}
  return a:inner ? s:Inset(l:rg) : {'lw': 0, 'rg': l:rg}
endfunction

function! s:SelectRange(sel) abort
  let l:rg = a:sel.rg
  if get(a:sel, 'lw', 0)
    execute 'normal! ' . (l:rg.start.line + 1) . 'GV' . (l:rg.end.line + 1) . 'G'
    return
  endif
  call cursor(l:rg.start.line + 1, l:rg.start.character + 1)
  normal! v
  let l:lnum = l:rg.end.line + 1
  " LSP end is exclusive and 0-based, so the last included column is end.character
  " once both are converted to 1-based. A 0 means the range stops at a line start.
  let l:col = l:rg.end.character
  if l:col <= 0
    let l:lnum -= 1
    let l:col = max([1, col([l:lnum, '$']) - 1])
  endif
  call cursor(l:lnum, l:col)
endfunction

function! s:SelectConstruct(inner) abort
  let l:sel = s:Construct(a:inner)
  if empty(l:sel)
    " No language server: Kconfig, Makefiles, .S, .dts, and any .c that is missing
    " from compile_commands.json. Vim's own brace block is the @block third of
    " nvim's `o`, so degrade to that rather than failing outright.
    let l:sel = s:BraceBlock(a:inner)
  endif
  if !empty(l:sel)
    call s:SelectRange(l:sel)
  endif
endfunction

onoremap <silent> ao :<C-u>call <SID>SelectConstruct(0)<CR>
onoremap <silent> io :<C-u>call <SID>SelectConstruct(1)<CR>
xnoremap <silent> ao :<C-u>call <SID>SelectConstruct(0)<CR>
xnoremap <silent> io :<C-u>call <SID>SelectConstruct(1)<CR>

" ---- ]f / [f : function motions ---------------------------------------------
" ]] and [[ jump between column-0 braces, which in kernel C is exactly a function
" boundary. They already push the jumplist (upstream's set_jumps=true) and already
" honour counts, and unlike an LSP motion they keep working in headers, macro soup
" and files clangd has no compile command for. ][ and [] are the matching end
" motions, mirroring nvim's ]F/[F.
"
" Divergence from nvim: these land on the brace line, not the signature line.
" Do NOT reach for ]m/[m instead -- they are brace-based and Java-shaped, and in C
" they land inside the function on things like `while (1) {`.
"
" Mapping these in NORMAL mode is also what displaces vim-unimpaired's ]f/[f
" (next/previous file in the directory). unimpaired guards every map with
" `empty(maparg(...))` and is deferred to SafeState by 95-, so vimrc.d always wins
" -- but the guard is per-key and mode-exact, so both directions must be bound here
" or one half of the pair silently stays unimpaired's.
for s:mode in ['n', 'x', 'o']
  execute s:mode . 'noremap ]f ]]'
  execute s:mode . 'noremap [f [['
  execute s:mode . 'noremap ]F ]['
  execute s:mode . 'noremap [F []'
endfor
unlet s:mode

" ---- af / if / ac / ic : degrade instead of throwing -------------------------
" 50-coc.vim binds these straight to coc's <Plug>s, which raise
" `coc.nvim not ready when invoke CocAction "selectSymbolRange"` before the service
" starts, and coc's own provider error in any buffer with no documentSymbol. For
" kernel work that is not an edge case -- Kconfig, Makefiles, .S and .dts hit it
" daily. Same kinds as coc uses (plugin/coc.vim:825-833), just guarded.
"
" No fallback on purpose: `af` quietly behaving like `aB` would delete the enclosing
" brace block instead of the function, and these are operator targets.
function! s:SymbolObj(inner, kinds, vmode) abort
  if s:CocReady()
    try
      call CocAction('selectSymbolRange', a:inner, a:vmode, a:kinds)
      return
    catch
    endtry
  endif
  echohl WarningMsg | echo 'textobj: no LSP symbols here' | echohl None
endfunction

onoremap <silent> af :<C-u>call <SID>SymbolObj(v:false, ['Method', 'Function'], '')<CR>
onoremap <silent> if :<C-u>call <SID>SymbolObj(v:true,  ['Method', 'Function'], '')<CR>
onoremap <silent> ac :<C-u>call <SID>SymbolObj(v:false, ['Interface', 'Struct', 'Class'], '')<CR>
onoremap <silent> ic :<C-u>call <SID>SymbolObj(v:true,  ['Interface', 'Struct', 'Class'], '')<CR>
xnoremap <silent> af :<C-u>call <SID>SymbolObj(v:false, ['Method', 'Function'], visualmode())<CR>
xnoremap <silent> if :<C-u>call <SID>SymbolObj(v:true,  ['Method', 'Function'], visualmode())<CR>
xnoremap <silent> ac :<C-u>call <SID>SymbolObj(v:false, ['Interface', 'Struct', 'Class'], visualmode())<CR>
xnoremap <silent> ic :<C-u>call <SID>SymbolObj(v:true,  ['Interface', 'Struct', 'Class'], visualmode())<CR>
