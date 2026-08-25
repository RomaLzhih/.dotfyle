" 56-navigation.vim -- structural motions that need no language support.
"
" Sourced after 55-textobjects.vim (LSP-backed objects) and before 60-. Nothing
" here needs an augroup except the diff/patch block at the bottom, which owns the
" single `autocmd!` for this file.
"
" Design bias: everything in this file works in EVERY filetype. 55- leans on clangd
" and degrades where there is no server; these motions lean on indentation and on
" the buffer's own text, so they behave identically in C, Python, Rust, Lua, YAML,
" JSON, Markdown and a Makefile.
"
" All motions use <Cmd> rather than :<C-u>. <Cmd> does not change mode, so one rhs
" serves normal, visual (the selection extends instead of collapsing) and, with a
" leading V to force linewise, operator-pending. v:count1 survives it.

" ---- ]i / [i : next/previous line at the SAME indent ------------------------
" Sibling navigation -- the most general structural motion available, because it
" needs no parser at all. In Python it walks sibling statements and def-to-def; in
" C it walks the statements of a block without descending into nested ones; in
" YAML/JSON it walks keys at one level; in Markdown it walks list items.
"
" Shadows the BUILTIN [i/]i (show the first line matching the keyword under the
" cursor, searching 'path' includes). That builtin is NORMAL-MODE ONLY, so the x
" and o bindings below shadow nothing at all, and the normal-mode loss is real but
" small -- :ilist and :isearch remain, and gd/coc's gd cover the same ground better.

" Lines that are not siblings even when their indent matches: blanks, and a lone
" closing delimiter (so the `}` of a nested block is not a peer of the statements
" above it). Preprocessor lines are skipped only when we are inside an indented
" block -- at indent 0 `#define`/`#include` runs ARE the siblings you want.
function! s:IndentSkip(lnum, base) abort
  let l:line = getline(a:lnum)
  if l:line =~# '^\s*$'
    return 1
  endif
  if l:line =~# '^\s*[]})]'
    return 1
  endif
  return a:base > 0 && l:line =~# '^\s*#'
endfunction

function! s:IndentMove(fwd, cnt) abort
  let l:base = indent('.')
  let l:step = a:fwd ? 1 : -1
  let l:last = line('$')
  let l:from = line('.')
  let l:lnum = l:from
  let l:left = a:cnt
  while l:left > 0
    let l:probe = l:lnum + l:step
    let l:hit = 0
    while l:probe >= 1 && l:probe <= l:last
      if !s:IndentSkip(l:probe, l:base)
        if indent(l:probe) == l:base
          let l:hit = l:probe
          break
        endif
        " Dedented past the block: there are no more siblings this way.
        if indent(l:probe) < l:base
          break
        endif
      endif
      let l:probe += l:step
    endwhile
    if l:hit == 0
      break
    endif
    let l:lnum = l:hit
    let l:left -= 1
  endwhile
  if l:lnum != l:from
    " m' pushes the jumplist, so <C-o> comes back. Motions are not jump commands
    " by default; ]] and [[ are, which is why 55-'s ]f/[f need no such line.
    normal! m'
    call cursor(l:lnum, 1)
    normal! ^
  endif
endfunction

nnoremap <silent> ]i <Cmd>call <SID>IndentMove(1, v:count1)<CR>
nnoremap <silent> [i <Cmd>call <SID>IndentMove(0, v:count1)<CR>
xnoremap <silent> ]i <Cmd>call <SID>IndentMove(1, v:count1)<CR>
xnoremap <silent> [i <Cmd>call <SID>IndentMove(0, v:count1)<CR>
onoremap <silent> ]i V<Cmd>call <SID>IndentMove(1, v:count1)<CR>
onoremap <silent> [i V<Cmd>call <SID>IndentMove(0, v:count1)<CR>

" ---- ii / ai : the indent block as a text object ----------------------------
" The object half of ]i/[i, and the stand-in for kana/vim-textobj-indent, which
" cannot be installed here (no network from this host; nothing under plugged/).
" Also what nvim has via snacks.nvim's scope module, on the same two keys.
"
" ii = the contiguous run of lines at this indent or deeper.
" ai = that plus the header line above it (the def/if/for/key that introduces it).
"
" Safe against targets.vim: it maps only the bare `i`/`a` as <expr> and reads the
" next key itself, and its modifiers are n/l/I/A -- `i` and `a` are not among them,
" so `ii`/`ai` are complete matches that take nothing away.
function! s:IndentBlock(outer) abort
  let l:base = indent('.')
  let l:last = line('$')
  let l:top = line('.')
  while l:top > 1
    let l:p = l:top - 1
    if getline(l:p) !~# '^\s*$' && indent(l:p) < l:base
      break
    endif
    let l:top = l:p
  endwhile
  let l:bot = line('.')
  while l:bot < l:last
    let l:n = l:bot + 1
    if getline(l:n) !~# '^\s*$' && indent(l:n) < l:base
      break
    endif
    let l:bot = l:n
  endwhile
  " Blank lines were bridged so a run split by them stays one block; trim the ones
  " that ended up on the edges.
  while l:top < l:bot && getline(l:top) =~# '^\s*$'
    let l:top += 1
  endwhile
  while l:bot > l:top && getline(l:bot) =~# '^\s*$'
    let l:bot -= 1
  endwhile
  if a:outer && l:top > 1 && indent(l:top - 1) < l:base
    let l:top -= 1
  endif
  return [l:top, l:bot]
endfunction

" Text objects keep the :<C-u> + establish-a-visual-selection idiom from 55-:
" the pending operator applies to whatever selection the function leaves behind.
function! s:IndentObj(outer) abort
  if getline('.') =~# '^\s*$'
    return
  endif
  let [l:top, l:bot] = s:IndentBlock(a:outer)
  execute 'normal! ' . l:top . 'GV' . l:bot . 'G'
endfunction

xnoremap <silent> ii :<C-u>call <SID>IndentObj(0)<CR>
onoremap <silent> ii :<C-u>call <SID>IndentObj(0)<CR>
xnoremap <silent> ai :<C-u>call <SID>IndentObj(1)<CR>
onoremap <silent> ai :<C-u>call <SID>IndentObj(1)<CR>

" ---- ]r / [r : next/previous occurrence of the symbol under the cursor ------
" What `*`/`n` almost gives you, minus the damage: this leaves @/ and hlsearch
" untouched, so it does not blow away the search you are in the middle of.
"
" Backed by CocAction('symbolRanges') -- the LSP documentHighlight ranges coc
" ALREADY computes on every CursorHold (50-coc.vim:337 dispatches it, coc-highlight
" is installed). Verified live: on `total` in a C buffer it returned exactly the 5
" real occurrences. That matters more than it sounds -- a textual \<word\> search
" for `ret`, `err`, `i` or `len` matches every unrelated local in every other
" function, plus comments and strings, which is precisely the class of identifier
" you chase most. The textual search is kept only as the no-LSP fallback.
"
" vimtex owns ]r/[r buffer-locally in .tex (next/previous \begin{frame}). It guards
" with empty(maparg(...)) and does not override, so these globals win there and the
" frame motion is lost -- a deliberate trade, noted in CLAUDE.md.
function! s:OccurrenceRanges() abort
  if !exists('*CocAction') || !get(g:, 'coc_service_initialized', 0)
    return []
  endif
  try
    let l:r = CocAction('symbolRanges')
  catch
    return []
  endtry
  return type(l:r) == v:t_list ? l:r : []
endfunction

function! s:OccurrenceSearch(fwd, cnt) abort
  let l:word = expand('<cword>')
  if empty(l:word) || l:word !~# '\k'
    return
  endif
  let l:save = @/
  normal! m'
  for l:_ in range(a:cnt)
    call search('\V\<' . escape(l:word, '\') . '\>', a:fwd ? 'w' : 'bw')
  endfor
  let @/ = l:save
endfunction

function! s:Occurrence(fwd, cnt) abort
  let l:ranges = s:OccurrenceRanges()
  if empty(l:ranges)
    return s:OccurrenceSearch(a:fwd, a:cnt)
  endif
  " LSP ranges are 0-based and arrive unordered.
  let l:all = map(copy(l:ranges), '[v:val.start.line, v:val.start.character]')
  call sort(l:all, {a, b -> a[0] == b[0] ? a[1] - b[1] : a[0] - b[0]})
  let l:here = [line('.') - 1, col('.') - 1]
  let l:ahead = filter(copy(l:all), a:fwd
        \ ? 'v:val[0] > l:here[0] || (v:val[0] == l:here[0] && v:val[1] > l:here[1])'
        \ : 'v:val[0] < l:here[0] || (v:val[0] == l:here[0] && v:val[1] < l:here[1])')
  if empty(l:ahead)
    " Wrap, matching how `n` behaves with 'wrapscan'.
    let l:ahead = [a:fwd ? l:all[0] : l:all[-1]]
  elseif !a:fwd
    call reverse(l:ahead)
  endif
  let l:target = l:ahead[min([a:cnt, len(l:ahead)]) - 1]
  normal! m'
  call cursor(l:target[0] + 1, l:target[1] + 1)
endfunction

nnoremap <silent> ]r <Cmd>call <SID>Occurrence(1, v:count1)<CR>
nnoremap <silent> [r <Cmd>call <SID>Occurrence(0, v:count1)<CR>
xnoremap <silent> ]r <Cmd>call <SID>Occurrence(1, v:count1)<CR>
xnoremap <silent> [r <Cmd>call <SID>Occurrence(0, v:count1)<CR>
onoremap <silent> ]r <Cmd>call <SID>Occurrence(1, v:count1)<CR>
onoremap <silent> [r <Cmd>call <SID>Occurrence(0, v:count1)<CR>

" ---- diff / patch buffers ---------------------------------------------------
" A .patch or `git format-patch` mbox is dead ground today: the builtin ]] finds no
" column-0 `{` and runs to EOF, and signify's ]d/[d never attach because the patch
" file is not tracked. Both get a meaning here from the diff's own structure.
"
" ]f/[f are deliberately NOT touched. 55- binds them with `noremap ]f ]]`, so they
" resolve to the BUILTIN ]] and are unaffected by the buffer-local ]] below.
"
" Neither ]] nor ]d is a vim-unimpaired key, so this dodges the hazard CLAUDE.md
" describes: a buffer-local map installed at FileType lands before unimpaired loads
" at SafeState, and its maparg() guard is mode-exact and sees the current buffer.
function! s:DiffJump(pat, back) abort
  normal! m'
  call search(a:pat, a:back ? 'bW' : 'W')
endfunction

function! s:DiffMaps() abort
  nnoremap <buffer><silent> ]] <Cmd>call <SID>DiffJump('^diff --git', 0)<CR>
  nnoremap <buffer><silent> [[ <Cmd>call <SID>DiffJump('^diff --git', 1)<CR>
  nnoremap <buffer><silent> ]d <Cmd>call <SID>DiffJump('^@@', 0)<CR>
  nnoremap <buffer><silent> [d <Cmd>call <SID>DiffJump('^@@', 1)<CR>
endfunction

augroup vimrc_navigation
  autocmd!
  autocmd FileType diff,git call s:DiffMaps()
augroup END
