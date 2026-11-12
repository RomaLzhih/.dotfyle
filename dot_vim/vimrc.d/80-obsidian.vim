" 80-obsidian.vim -- edit the Obsidian vault from Vim.
"
" obsidian.nvim is Lua and cannot load here, so this ports the part of it (v3.9.0,
" the release nvim pins) that the nvim config actually exercises, onto fzf +
" ripgrep + vimscript. Same command names, same keys:
"
"   <leader>id  :ObsidianSearch [query]   live ripgrep over the vault, from any cwd
"               :ObsidianQuickSwitch      pick a note, most recently modified first
"               :ObsidianNew [title]      new note with obsidian.nvim's frontmatter
"   in a vault note
"     <CR>        follow the link under the cursor, else toggle the checkbox
"     gf          follow the link under the cursor, else the builtin gf
"     <leader>ch  toggle the checkbox
"     :w          adds the id/aliases/tags frontmatter obsidian.nvim maintains
"
" Not ported, because nothing in the vault uses them: daily notes, templates,
" backlinks, tags, rename, paste-image, completion. Where this behaves differently
" from nvim on purpose the comment says DIVERGES. See ~/.vim/CLAUDE.md.

" Same vault as nvim's `workspaces` (~/.config/nvim/lua/plugins/others.lua). Where
" the directory does not exist everything below is inert: the commands warn, and
" the autocmds return on their first test. nvim gates the plugin by OS instead.
let g:obsidian_vault = get(g:, 'obsidian_vault', has('mac')
      \ ? '~/Library/CloudStorage/Dropbox/work-flow/obsidian/ziyang-obsidian'
      \ : '~/Dropbox/work-flow/obsidian/ziyang-obsidian')
" obsidian.nvim's default ui.checkboxes order. nvim sets `ui = { enable = false }`,
" which turns off the rendering but leaves this cycle in force.
let g:obsidian_checkboxes = get(g:, 'obsidian_checkboxes', [' ', '~', '!', '>', 'x'])

function! s:Warn(msg) abort
  echohl WarningMsg | echomsg 'Obsidian: ' . a:msg | echohl None
endfunction

" One line, cut to what fits: a long URL would otherwise raise the hit-enter prompt.
function! s:Echo(msg) abort
  let l:msg = a:msg
  while !empty(l:msg) && strdisplaywidth(l:msg) > v:echospace
    let l:msg = strcharpart(l:msg, 0, strchars(l:msg) - 1)
  endwhile
  echo l:msg
endfunction

" The vault root: absolute, resolved, no trailing slash. resolve() goes on both
" sides of every prefix test, because a buffer can arrive under a symlinked name
" (the ~/fbsource note in 30-) and the two spellings must agree.
function! s:Vault() abort
  if get(s:, 'vault_src', '') !=# g:obsidian_vault
    let s:vault_src = g:obsidian_vault
    let s:vault = substitute(resolve(fnamemodify(expand(g:obsidian_vault), ':p')), '/\+$', '', '')
  endif
  return s:vault
endfunction

function! s:InVault(path) abort
  if empty(a:path)
    return 0
  endif
  let l:root = s:Vault() . '/'
  return resolve(fnamemodify(a:path, ':p'))[: len(l:root) - 1] ==# l:root
endfunction

function! s:VaultOk() abort
  if isdirectory(s:Vault())
    return 1
  endif
  call s:Warn('vault not found: ' . g:obsidian_vault)
  return 0
endfunction

" ---- search / quick switch ----
function! s:FzfOk() abort
  if exists(':RG') == 2
    return s:VaultOk()
  endif
  call s:Warn('fzf.vim is not loaded')
  return 0
endfunction

" obsidian.nvim hands the query to its picker's live grep. This is fzf.vim's :RG
" with 'dir' pointed at the vault, so it works from any cwd and leaves the cwd
" alone. `--no-config --type=md` is obsidian.nvim's own ripgrep base command.
function! s:Search(query, bang) abort
  if !s:FzfOk()
    return
  endif
  call fzf#vim#grep2('rg --column --line-number --no-heading --color=always --smart-case'
        \ . ' --no-config --type=md -- ', a:query,
        \ fzf#vim#with_preview({'dir': s:Vault(), 'options': ['--prompt', 'Obsidian> ']}),
        \ a:bang)
endfunction

" Newest first, obsidian.nvim's default order (sort_by = "modified", reversed);
" fzf keeps the input order until a query is typed.
" DIVERGES: an argument is the starting query. nvim resolves it straight to a note
" when exactly one matches.
function! s:QuickSwitch(query, bang) abort
  if !s:FzfOk()
    return
  endif
  call fzf#vim#files(s:Vault(), fzf#vim#with_preview({
        \ 'source': 'rg --files --no-config --type=md --sortr=modified',
        \ 'options': ['--prompt', 'Notes> ', '--query', a:query]}), a:bang)
endfunction

" ---- links ----
" obsidian.nvim's reference patterns (search.lua) as Vim regexes, in its priority
" order. The `!` of an embed is part of the span here, so the cursor may sit on it.
let s:link_patterns = [
      \ ['wiki', '!\=\[\[[^][]\+\]\]'],
      \ ['md',   '!\=\[[^][]\+\]([^)]\+)'],
      \ ['url',  'https\=://[a-zA-Z0-9._-]\+[a-zA-Z0-9._#/=&?:+%-]\+[a-zA-Z0-9/]'],
      \ ]
" Anything with a scheme is handed to the desktop rather than looked up as a note.
let s:url = '^\%(\a[a-zA-Z0-9+.-]*://\|mailto:\)'

function! s:ParseLink(kind, text) abort
  if a:kind ==# 'url'
    return {'kind': 'url', 'target': a:text, 'label': a:text}
  elseif a:kind ==# 'md'
    let l:m = matchlist(a:text, '^!\=\[\(.\{-}\)\](\(.*\))$')
    " [label](<target> "title") -- drop the title and the angle brackets.
    let l:target = substitute(trim(l:m[2]), '\s\+["''].*["'']$', '', '')
    return {'kind': 'md', 'target': substitute(l:target, '^<\(.*\)>$', '\1', ''), 'label': l:m[1]}
  endif
  " [[target|label]]. `\|` is how the pipe is written inside a table cell.
  let l:body = substitute(matchstr(a:text, '^!\=\[\[\zs.*\ze\]\]$'), '\\|', '|', 'g')
  let l:bar = stridx(l:body, '|')
  let l:target = trim(l:bar < 0 ? l:body : strpart(l:body, 0, l:bar))
  return {'kind': 'wiki', 'target': l:target, 'embed': a:text[0] ==# '!',
        \ 'label': l:bar < 0 ? l:target : trim(strpart(l:body, l:bar + 1))}
endfunction

" The link at byte column a:col of a:line as {kind, target, label}, or {} if
" there is none. A link inside inline `code` is text, as in obsidian.nvim.
function! s:LinkAt(line, col) abort
  let l:code = []
  let l:from = 0
  while 1
    let [l:text, l:s, l:e] = matchstrpos(a:line, '`[^`]*`', l:from)
    if l:s < 0
      break
    endif
    call add(l:code, [l:s, l:e])
    let l:from = l:e
  endwhile
  let l:at = a:col - 1
  for [l:kind, l:pat] in s:link_patterns
    let l:from = 0
    while 1
      let [l:text, l:s, l:e] = matchstrpos(a:line, l:pat, l:from)
      if l:s < 0
        break
      endif
      let l:from = l:e
      if l:at < l:s || l:at >= l:e
        continue
      endif
      for [l:cs, l:ce] in l:code
        if l:cs < l:s && l:e < l:ce
          return {}
        endif
      endfor
      return s:ParseLink(l:kind, l:text)
    endwhile
  endfor
  return {}
endfunction

" DIVERGES: obsidian.nvim only warns on a URL unless follow_url_func is set (nvim
" sets none), and for an embed offers to create a note called `image.png`. Here
" both go to the desktop: http(s) to the browser, zotero:// to Zotero, an image to
" the viewer. A List for job_start(), so there is no shell and nothing to escape.
function! s:OpenExternal(target) abort
  let l:cmd = get(g:, 'obsidian_open_cmd', [has('mac') ? 'open' : 'xdg-open'])
  if !executable(l:cmd[0])
    return s:Warn(l:cmd[0] . ' is not available to open ' . a:target)
  endif
  call job_start(l:cmd + [a:target], {
        \ 'in_io': 'null', 'out_io': 'null', 'err_io': 'null', 'stoponexit': '',
        \ 'exit_cb': {job, code -> code ? s:Warn('could not open ' . a:target) : 0}})
  call s:Echo('Opening ' . a:target)
endfunction

" Obsidian's own rule: a link is a path or a bare file name, `.md` optional, case
" ignored, the shortest path winning a tie. One `rg --files` and a string compare
" rather than a glob, since names here carry spaces, CJK and could carry brackets.
" DIVERGES: obsidian.nvim also matches a note's frontmatter `id` and aliases. The
" vault has no note-to-note link to resolve that way, so the lookup stays on names.
function! s:Resolve(name) abort
  " Relative to this note first: that is what [x](../notes/y.md) means.
  for l:try in [a:name, a:name . '.md']
    let l:local = simplify(expand('%:p:h') . '/' . l:try)
    if filereadable(l:local)
      return l:local
    endif
  endfor
  let l:root = s:Vault()
  let l:want = substitute(tolower(a:name), '^\.\=/', '', '')
  let l:tail = fnamemodify(l:want, ':t')
  let [l:best, l:rank] = ['', 9]
  for l:file in systemlist('rg --files --no-config ' . shellescape(l:root))
    let l:rel = tolower(strpart(l:file, len(l:root) + 1))
    let l:base = fnamemodify(l:rel, ':t')
    if l:rel ==# l:want || l:rel ==# l:want . '.md'
      let l:r = 0
    elseif l:base ==# l:tail || l:base ==# l:tail . '.md'
      let l:r = 1
    else
      continue
    endif
    if l:r < l:rank || (l:r == l:rank && len(l:file) < len(l:best))
      let [l:best, l:rank] = [l:file, l:r]
    endif
  endfor
  return l:best
endfunction

" obsidian.nvim's standardize_anchor(): lower case, blanks to '-', punctuation
" dropped. DIVERGES: only ASCII punctuation is dropped -- Lua's %w is ASCII, so
" nvim reduces a CJK heading to nothing and can never land on it.
function! s:Anchor(text) abort
  return substitute(substitute(tolower(trim(a:text)), '\s', '-', 'g'),
        \ '[^#_[:alnum:]-]\&[\x01-\x7f]', '', 'g')
endfunction

" a:tail is the '#Heading', '#H1#H2' or '#^block' part of a link, or ''.
function! s:GotoAnchor(tail) abort
  let l:seg = matchstr(a:tail, '[^#]*$')
  if empty(l:seg)
    return
  endif
  let l:lnum = 0
  if l:seg[0] ==# '^'
    let l:lnum = search('\V\s' . escape(l:seg, '\') . '\s\*\$', 'cnw')
  else
    let l:want = s:Anchor(l:seg)
    let l:fenced = 0
    for l:n in range(1, line('$'))
      let l:text = getline(l:n)
      if l:text =~# '^\s*\%(```\|\~\~\~\)'
        let l:fenced = !l:fenced
      elseif !l:fenced && l:text =~# '^#\+\s\+\S'
            \ && s:Anchor(substitute(l:text, '^#\+\s\+', '', '')) ==# l:want
        let l:lnum = l:n
        break
      endif
    endfor
  endif
  if l:lnum
    normal! m'
    call cursor(l:lnum, 1)
    normal! zv
  endif
endfunction

function! s:FollowLink() abort
  let l:link = s:LinkAt(getline('.'), col('.'))
  if empty(l:link)
    return
  endif
  if l:link.target =~? s:url
    return s:OpenExternal(l:link.target)
  endif
  " Obsidian follows URL-encoded locations: [x](My%20Note.md). Decoded byte by
  " byte, so a percent-encoded CJK name comes back as UTF-8, not as Latin-1.
  let l:target = substitute(l:link.target, '%\(\x\x\)',
        \ '\=eval(''"\x'' . submatch(1) . ''"'')', 'g')
  " Split off #Heading / #^block. `C#` and `C# notes` stay file names, as in
  " obsidian.nvim, because an anchor has to start with something after the `#`.
  let l:anchor = matchstr(l:target, '\%(#\^\=[^#[:space:]^][^#]*\)\+$')
  let l:name = strpart(l:target, 0, len(l:target) - len(l:anchor))
  if !empty(l:name)
    let l:path = s:Resolve(l:name)
    if empty(l:path)
      " obsidian.nvim offers to create the missing note -- wiki links only.
      if l:link.kind !=# 'wiki' || l:link.embed || !isdirectory(s:Vault())
        return s:Warn('cannot resolve ' . l:name)
      endif
      if confirm("Create new note '" . l:name . "'?", "&Yes\n&No", 1) == 1
        call s:NewNote(l:name, l:link.label ==# l:link.target ? '' : l:link.label)
      endif
      return
    endif
    if l:path !~? '\.md$'
      return s:OpenExternal(l:path)
    endif
    " Not :edit on the note we are in: that is a reload, E37 once it is modified.
    if resolve(l:path) !=# resolve(expand('%:p'))
      execute 'edit ' . fnameescape(l:path)
    endif
  endif
  call s:GotoAnchor(l:anchor)
endfunction

" ---- new notes ----
" obsidian.nvim's yaml should_quote(): where a bare scalar would not read back as
" the same string. Only `"` is escaped inside the quotes, as there.
function! s:YamlStr(str) abort
  if a:str =~# '^["''\\[{&!-]' || a:str =~# '^[0-9.-]\+$'
        \ || stridx(a:str, ': ') >= 0 || a:str =~# '^\s*$'
    return '"' . escape(a:str, '"') . '"'
  endif
  return a:str
endfunction

" Open an unsaved buffer scaffolded the way :ObsidianNew does in nvim for a title
" given with `.md`: id = the file name, the title as its one alias, and an H1.
" a:where is a title, optionally with vault-relative folders in front and `.md`
" behind; a bare title lands next to the current note, or at the vault root when
" the current buffer is not in the vault (obsidian.nvim's new_notes_location).
" DIVERGES: a bare title names the file. nvim's default is a Zettel id
" (1731312000-ABCD.md) with the title surviving only as alias -- and every note
" that still carries such an id has since been renamed to a real title.
function! s:NewNote(where, title) abort
  let l:where = substitute(trim(a:where), '\.md$', '', '')
  let l:id = fnamemodify(l:where, ':t')
  if empty(l:id)
    return s:Warn('Aborted')
  endif
  if l:where =~# '/'
    let l:dir = s:Vault() . '/' . fnamemodify(l:where, ':h')
  else
    let l:dir = s:InVault(expand('%:p')) ? expand('%:p:h') : s:Vault()
  endif
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif
  execute 'edit ' . fnameescape(simplify(l:dir . '/' . l:id . '.md'))
  if line('$') == 1 && empty(getline(1))
    let l:title = empty(a:title) ? l:id : a:title
    call setline(1, ['---', 'id: ' . s:YamlStr(l:id), 'aliases:', '  - ' . s:YamlStr(l:title),
          \ 'tags: []', '---', '', '# ' . l:title])
    call cursor(line('$'), 1)
  endif
endfunction

function! s:New(arg) abort
  if s:VaultOk()
    call s:NewNote(empty(a:arg) ? input('Enter title or path: ', '', 'file') : a:arg, '')
  endif
endfunction

" ---- checkboxes ----
" obsidian.nvim's util.toggle_checkbox(), rule for rule: a line that is not a
" `- [ ] ` item becomes one -- a plain paragraph line too, so <CR> anywhere off a
" link makes a task, exactly as in nvim -- and an item steps to the next state in
" g:obsidian_checkboxes. A state outside that list ([p], [c]) is left alone.
function! s:ToggleCheckbox() abort
  let l:old = getline('.')
  let l:new = l:old
  if l:old !~# '^\s*- \[.\] '
    let l:new = l:old =~# '^\s*[-*+] '
          \ ? substitute(l:old, '^\(\s*\)[-*+] ', '\1- [ ] ', '')
          \ : substitute(l:old, '^\s*', '\0- [ ] ', '')
  else
    let l:count = len(g:obsidian_checkboxes)
    for l:i in range(l:count)
      if l:old =~# '^\s*- \[\V' . escape(g:obsidian_checkboxes[l:i], '\') . '\m\]'
        let l:next = g:obsidian_checkboxes[(l:i + 1) % l:count]
        let l:new = substitute(l:old, '- \[.\]', '- [' . escape(l:next, '\&~') . ']', '')
        break
      endif
    endfor
  endif
  if l:new !=# l:old
    call setline('.', l:new)
  endif
endfunction

" ---- frontmatter on write ----
" obsidian.nvim rewrites the frontmatter on every BufWritePre: id (defaulting to
" the file name), aliases and tags first, then every other key re-serialised and
" sorted. This does the part that needs no YAML round-trip: a note without
" frontmatter gets the block, and a block missing one of the three keys gets that
" key, in obsidian.nvim's order.
" DIVERGES: nothing already in the block is rewritten, so hand-written and Zotero
" frontmatter keeps its formatting until nvim next saves the note.

" Top-level key -> last line of its value, for the block ending at line a:last.
function! s:FrontmatterKeys(last) abort
  let l:keys = {}
  let l:cur = ''
  for l:n in range(2, a:last - 1)
    let l:text = getline(l:n)
    let l:key = matchstr(l:text, '^[A-Za-z_][^:[:space:]]*\ze:\%(\s\|$\)')
    if !empty(l:key)
      let l:cur = l:key
      let l:keys[l:key] = l:n
    elseif !empty(l:cur) && l:text =~# '\S'
      let l:keys[l:cur] = l:n
    endif
  endfor
  return l:keys
endfunction

function! s:Frontmatter(file) abort
  if !&modifiable || !s:InVault(a:file)
    return
  endif
  let l:id = 'id: ' . s:YamlStr(fnamemodify(a:file, ':t:r'))
  if getline(1) !~# '^---\+\s*$'
    " The blank separator only where the note does not already start with one.
    call append(0, ['---', l:id, 'aliases: []', 'tags: []', '---']
          \ + (getline(1) =~# '\S' ? [''] : []))
    return
  endif
  let l:last = 0
  for l:n in range(2, line('$'))
    if getline(l:n) =~# '^---\+\s*$'
      let l:last = l:n
      break
    endif
  endfor
  if !l:last
    return
  endif
  let l:after = 1
  for [l:key, l:text] in [['id', l:id], ['aliases', 'aliases: []'], ['tags', 'tags: []']]
    let l:keys = s:FrontmatterKeys(l:last)
    if has_key(l:keys, l:key)
      let l:after = l:keys[l:key]
    else
      call append(l:after, l:text)
      let l:after += 1
      let l:last += 1
    endif
  endfor
endfunction

" ---- syntax ----
" vim-markdown knows no wikilink, no ==highlight== and only the [ ] [x] [o]
" checkboxes. Vault notes only -- `==` and `[[` mean other things in a README.
" The frontmatter itself is g:vim_markdown_frontmatter, set in 30-.
"
" Called from ~/.vim/after/syntax/markdown.vim, which is why it is global. NOT
" from a `Syntax markdown` autocmd, though that passes every first test: each
" `:syntax enable` re-sources synload.vim, whose `au! Syntax *` re-registers the
" runtime's own handler BEHIND ours. From then on ours runs first and the
" runtime's `syntax clear` wipes what it added. The runtime sources after/syntax
" itself, last, so there is no order to lose.
" Links, never attributes, so 40-'s sweep skips these groups (CLAUDE.md §2).
highlight default link obsidianLink     Underlined
highlight default link obsidianMark     Search
highlight default link obsidianCheckbox Identifier

function! ObsidianSyntax() abort
  if !s:InVault(expand('%:p'))
    return
  endif
  syntax match obsidianLink /!\=\[\[[^][]\+\]\]/
  syntax match obsidianMark /==[^=[:space:]]\%([^=]*[^=[:space:]]\)\===/
  syntax match obsidianCheckbox /\%(^\s*[-*+]\s\+\)\@<=\[[^]xXoO ]\]\ze\s/
  " Without these the items only match in paragraph text: list items, headings and
  " block quotes are regions that list what they may contain.
  syntax cluster mkdNonListItem    add=obsidianLink,obsidianMark,obsidianCheckbox
  syntax cluster mkdHeadingContent add=obsidianLink,obsidianMark
endfunction

" ---- mappings, commands ----
function! s:OnLink() abort
  return !empty(s:LinkAt(getline('.'), col('.')))
endfunction

" obsidian.nvim's smart_action and gf_passthrough.
function! s:SmartAction() abort
  return s:OnLink() ? "\<Cmd>ObsidianFollowLink\<CR>" : "\<Cmd>ObsidianToggleCheckbox\<CR>"
endfunction

function! s:GfPassthrough() abort
  return s:OnLink() ? "\<Cmd>ObsidianFollowLink\<CR>" : 'gf'
endfunction

" obsidian.nvim's three default mappings: normal mode, buffer-local, vault notes
" only. <leader>ch shadows `<leader>c` + `h` (OSC 52 yank of one character) in
" these buffers -- the collision nvim has too, where <leader>c is `"+y`.
function! s:BufferSetup() abort
  if !s:InVault(expand('%:p'))
    return
  endif
  nnoremap <buffer><silent><expr> <CR> <SID>SmartAction()
  nnoremap <buffer><silent><expr> gf   <SID>GfPassthrough()
  nnoremap <buffer><silent> <Leader>ch <Cmd>ObsidianToggleCheckbox<CR>
endfunction

" One augroup per file; only this block carries `autocmd!`.
augroup vimrc_obsidian
  autocmd!
  autocmd FileType markdown call s:BufferSetup()
  autocmd BufWritePre *.md call s:Frontmatter(expand('<afile>:p'))
augroup END

" Global, like obsidian.nvim's: the point is reaching the vault from a code buffer.
command! -bang -nargs=* ObsidianSearch      call s:Search(<q-args>, <bang>0)
command! -bang -nargs=* ObsidianQuickSwitch call s:QuickSwitch(<q-args>, <bang>0)
command! -nargs=? -complete=file ObsidianNew call s:New(<q-args>)
command! -bar ObsidianFollowLink     call s:FollowLink()
command! -bar ObsidianToggleCheckbox call s:ToggleCheckbox()

" nvim's key (lua/config/keymaps.lua). <leader>il and <leader>ic are the only
" other <leader>i maps, so it adds no new prefix wait.
nnoremap <silent> <Leader>id :ObsidianSearch<CR>

" The start screen's `i`: nvim's dashboard key for the same search. startify binds
" its entries after its own keys, so this takes over the builtin `i` (:enew +
" insert; <Insert> still does that, and `e` opens the empty buffer) -- which is why
" the entry is only added where the vault exists. Appended here rather than listed
" in 70-, because that file is sourced before the vault is known. The index() test
" keeps a re-source of this file alone from adding it twice.
let s:start_entry = {'i': ['Wiki: search the Obsidian vault', 'ObsidianSearch']}
if exists('g:startify_commands') && isdirectory(s:Vault())
      \ && index(g:startify_commands, s:start_entry) < 0
  call add(g:startify_commands, s:start_entry)
endif
