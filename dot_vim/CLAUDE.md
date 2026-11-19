# ~/.vim — agent guide

Vim 9.1.0113, terminal only (`-clipboard`, no GUI), always inside tmux.
Plugin manager: vim-plug. Companion Neovim config lives in `~/.config/nvim`.

`~/.vimrc` is only a loader: it sources `~/.vim/vimrc.d/*.vim` in sorted order.

---

## 1. Layout

| File | Owns |
|---|---|
| `00-plugins.vim` | the `vim-plug` list. **Must be first** |
| `10-options.vim` | core `:set`, bracketed paste, large-file gate, `autoread` |
| `20-mappings.vim` | `mapleader`, editing/motion maps, quickfix, tabs, resize, OSC 52 |
| `30-plugin-config.vim` | per-plugin settings (largest file): airline, fzf, context, bookmarks, asynctasks, easymotion, floaterm |
| `40-colorscheme.vim` | theme choice + cross-theme highlight normalisation |
| `50-coc.vim` | coc.nvim, `gd`, peek-definition popup, vim-signify signs |
| `55-textobjects.vim` | `ao`/`io` structural objects, `]f`/`[f` motions, LSP-object guards |
| `56-navigation.vim` | `]i`/`[i` + `ii`/`ai` indent, `]r`/`[r` occurrences, diff/patch maps |
| `60-coc-semantic.vim` | theme-adaptive LSP semantic-token colours |
| `70-sessions-startify.vim` | sessions and the start screen |
| `80-obsidian.vim` | Obsidian vault: search, quick switch, follow-link, checkbox toggle, frontmatter on write |
| `90-config-edit.vim` | `:Vimrc`, `:VimrcGrep` |
| `95-deferred-plugins.vim` | idle-time loading of `{'on': []}` plugins. **Must be last** |

Also: `autoload/airline/extensions/tabline/formatters/parentfile.vim` (tabline
format — must live at that path, airline resolves formatters by autoload name),
`coc-settings.json`, `bin/sy-diff.sh` (signify wrapper for untracked files),
`after/syntax/markdown.vim` (the hook for `80-`'s Obsidian syntax items — it must
live at that path too, see §4).

**Load order is load-bearing.** Plugins register before anything configures them;
`mapleader` before the maps that use it; the theme before 50-/60-, whose resolvers
read what the theme actually defines.

---

## 2. Rules that will bite you

**`s:` names are file-scoped.** An `s:` function and everything that calls it —
including `<SID>` mappings — must live in the same file.

**One augroup per file, and only the FIRST block in that file carries `autocmd!`.**
A bare `autocmd` *appends*, so re-sourcing stacks duplicates; but a second
`autocmd!` on the same group *wipes* the earlier block. Adding to `vimrc_plugins`
in `30-` means adding **after** the block that owns the clear, near the top.

**Never run `:highlight` on a linked group.** `synIDtrans()` resolves a link, so a
group linked to a bold one *reports* bold — and `:highlight` on it severs the link,
leaving no colours at all so it falls back to `Normal`. Skip anything where
`hlID(g) != synIDtrans(hlID(g))`; the link target is in the same list and gets
fixed on its own. koehler exposed this (`hi! link Conditional Statement` over a
bold `Statement` turned `if`/`while` white).

**vimrc.d is sourced before `plugin/**`.** So config here wins for plugins that
check `maparg()`/`hasmapto()` first (unimpaired does), and loses to plugins that
map unconditionally (vim-visual-multi does — hence `g:VM_maps`). Deferred plugins
(`95-`) load later still, at `SafeState`.

**Alt keys do not work.** No-GUI build under tmux; `:help map-alt-keys`. Where nvim
uses `<A-…>`, this config picks something else.

**Mirror the nvim config.** Look up the key in `~/.config/nvim` before binding
anything here, and flag a collision rather than inventing a key. Deliberate
divergences today: `]t`/`[t` (tabs here, unimpaired tags in nvim), `<Leader>tc`
(nvim uses LazyVim's `<leader><tab>d`), visual `*`/`#`, `<Leader>:`, `]f`/`[f`
(displaces unimpaired's directory nav), and `io` being linewise where mini.ai is charwise.
The Obsidian port in `80-` has its own list, in §4.

**Check what nvim actually *runs*, not what its config says.** The `textobjects = {…}`
block in `~/.config/nvim/lua/plugins/treesitter.lua` is **dead code** — it sits in the opts
of the `nvim-treesitter` spec, whose `setup()` reads only `install_dir`, and nothing
anywhere reads `opts.textobjects`. nvim's real text objects come from LazyVim's
**mini.ai** (`lazyvim/plugins/coding.lua`): `af`/`if` function, `ac`/`ic` class, `ao`/`io`
block/conditional/loop, `aa`/`ia` argument. Mirroring that dead block would have
repointed a working `ac`/`ic` and added an `al`/`il` that exists in neither editor.

---

## 3. Keys

Leader is `<Space>`; localleader is `\`.

**Files / search** `<C-f>` files · `?` lines in buffer · `<leader>ff` files ·
`<leader>gf` git files · `<leader>fw` ripgrep · `<leader>gw` rg word ·
`<leader>bb` buffers · `<leader>fr` recent (cwd) · `<leader>:` command history ·
`<leader>fj` jumps · `<leader>fk` marks · `<leader>/` fuzzy easymotion

**LSP (coc)** `gd` definition · `gt` type · `gi` impl · `gr` refs · `K` hover ·
`<leader>pd` peek popup · `<leader>rn` rename · `<leader>ca` code action ·
`<leader>qf` fix · `<leader>fm` format · `<leader>ot` outline · `<leader>fu`
symbols · `<leader>yk` yank ring · `]e`/`[e` diagnostics · `]d`/`[d` git hunks

**Text objects** `af`/`if` function · `ac`/`ic` class · `ao`/`io` block/conditional/loop ·
`ii`/`ai` indent block (`ai` adds the header line) · `aa`/`ia` argument (targets.vim) ·
`.` grow selection. Do **not** add `al`/`il` — see §4.

**Motions** `]f`/`[f` function, `]F`/`[F` its end · `]i`/`[i` next/prev line at the same
indent · `]r`/`[r` next/prev occurrence of the symbol under the cursor · `]e`/`[e`
diagnostics · `]d`/`[d` git hunks · `]t`/`[t` tabs · `]q`/`[q` quickfix · `]b`/`[b` buffers ·
`]n`/`[n` conflict markers. Press `]` or `[` alone for the which-key menu.

**Already there, easy to forget** — builtins: `]#`/`[#` unmatched `#if`/`#else`/`#endif` ·
`]/`/`[/` ends of a `/* */` block · `]}`/`[{` and `])`/`[(` unmatched brace/paren ·
`]%`/`[%` matchit · `g;`/`g,` changelist. unimpaired: `yos` spell, `yow` wrap, `yoh`
hlsearch, `yon` number, `yor` relativenumber, `yol` list, `yod` diffthis · `]p`/`[p`
indent-adjusted paste · `]<Space>`/`[<Space>` blank lines · `<Leader>j`/`<Leader>k` move
line (`]e`/`[e` still move a *visual* selection).

**In a diff/patch buffer** `]]`/`[[` next/prev file, `]d`/`[d` next/prev `@@` hunk.

**Windows / tabs / buffers** `<C-h/j/k/l>` navigate (tmux-aware) · `<C-arrow>`
resize · `<Tab>`/`<S-Tab>` cycle buffers · `]t`/`[t` tabs · `<leader>tc` close tab ·
`<leader>x` / `<leader>bd` close buffer · `<leader>op`/`<leader>pp` quickfix

**Bookmarks** `<leader>ha` toggle · `<leader>hh` list · `<leader>hn`/`<leader>hp`
next/prev · `<leader>hc`/`<leader>hx` clear. In the list: `1-9` jump, `i` annotate,
`dd` delete, `K`/`J` reorder.

**Obsidian** `<leader>id` live-grep the vault, from any cwd; `i` on the start screen does
the same. In a vault note only:
`<CR>` follow the link under the cursor, else toggle the checkbox · `gf` follow the link,
else the builtin · `<leader>ch` toggle the checkbox · `:w` adds missing frontmatter.

**Misc** `<leader>th` theme picker · `<leader>ve` edit config · `<leader>vg` grep
config · `<C-s>` yazi · `<C-g>` floaterm · `<leader>lg` lazygit · `<leader>c` OSC 52
yank · `*`/`#` in visual mode search the selection

**Commands** `:Vimrc[!]` `:VimrcGrep` `:Session` `:SessionLoad` `:Format` `:Fold`
`:OR` `:Inspect` `:SemCheck` `:HistoryCwd` `:AsyncTaskFzf` `:WQ` `:W`
`:ObsidianSearch` `:ObsidianQuickSwitch` `:ObsidianNew`

---

## 4. Design notes

**Themes are normalised, not patched.** `40-` strips italic and bold from every
group after any `:colorscheme`, and flattens the coloured slab some themes put
behind `TODO`. Two passes: a synchronous one, plus a `timer_start(0, …)` because
plugins register their own `ColorScheme` handlers later and re-add italics
(`hi default CocItalic`). `airline_*` keeps its bold on purpose.

**Semantic tokens resolve against the theme** (`60-`), never a hard-coded palette:
`theme's own group → treesitter @name → standard group → plain text`. Add a
`ColorScheme` override *above* that block to refine a theme.

**Colourschemes are lazy.** All but the active one are `{'on': []}`; a
`ColorSchemePre` hook in `30-` loads the owning plugin before Vim looks for
`colors/<name>.vim`. Native `:colorscheme <Tab>` only lists loaded ones — the
`<leader>th` picker lists all.

**vim-broadsheet is the user's own theme pack** — `swan-coffee`, `swan-graphite`,
`swan-tokyonight`, `swan-budapest-summer`, `swan-budapest-winter`, `swan-vga` and
`swan-phosphor`, from `RomaLzhih/vim-broadsheet`, which carries its own `CLAUDE.md`. All
seven carry the `swan-` prefix. `swan-budapest-winter` is the startup scheme (since
2026-11-19, replacing gruvbox), so this is the one colourscheme plugin that loads
eagerly; gruvbox is lazy with the rest. It has no `plugin/`, so loading it only puts it
on 'runtimepath'. The startup scheme is named in three places that must agree: the
`colorscheme` line in `40-`, the one colourscheme `Plug` in `00-` without `{'on': []}`,
and `g:airline_theme` in `30-`. The two budapest themes, `swan-vga` and `swan-phosphor`
ship airline themes that `AirlineFollowColorscheme` picks up by name — as
`swan_budapest_summer` and so on, because airline spells the hyphen as an underscore —
and the budapest pair's turn with `'background'`; the other three leave whatever
airline theme was active. Two things in
this config work against it, both known and both left alone: the sweep in `40-` removes
the bold and the italics its prose themes use as hierarchy, and `s:SignifyGitSignStyle()`
in `50-` repaints its sign colours with gruvbox's on every `ColorScheme` (the plugin's
notes carry the one-line guard).

**Sessions** are one file per project in `~/.local/state/vim/sessions`, named from
the cwd. Nothing loads on entry: a bare start shows the start screen and `p` there runs
`:SessionLoad` (`g:vimrc_session_autoload = 1` restores at VimEnter instead). A
loaded session rewrites on exit; a bare run that did *not* load an existing
session never overwrites it, only `w`/`:Session` does. Persistence writes only at `VimLeavePre`, so a SIGKILL loses the
session's changes. The start screen is wiped before saving — a session containing a
startify buffer fails to restore (`E121: g:startify_header`).

**Signs** come from vim-signify over git *and hg* (fbsource is Sapling), through
`bin/sy-diff.sh` so untracked files show as all-added.

**Structural text objects come from clangd's AST, not from a parser we wrote.** There is
no treesitter in Vim 9.1, but `textDocument/selectionRange` returns the *ancestry* of the
cursor, and that chain contains the enclosing block, conditional and loop as exact ranges.
`CocAction('selectionRanges')` hands it to vimscript — measured 3.1 ms on a kernel `.c`,
cheaper than the 14.8 ms `documentSymbols` round-trip `af`/`if` already pay. This is a
*different* API from `selectSymbolRange`, which backs coc's funcobj/classobj: that one is
`documentSymbol`-based, and LSP `SymbolKind` has no loop or conditional, so it can never
produce these. The hand-written alternative was scoped at ~850 lines and still got
do-while, dangling `else` and `list_for_each_entry` wrong — tree-sitter gets the last one
wrong too. When there is no server, `ao`/`io` fall back to the enclosing `{…}`.

**`al`/`il` is a trap.** targets.vim maps only the bare `i`/`a` as `<expr>` and consumes
the following keys itself, so `l` is its *"last"* modifier, not an object. Binding `il`
makes it a complete match and silently kills the whole `il(` / `al)` / `ilt` / `ila`
family. `ao`/`io` are free of targets' triggers and modifiers and of every Vim builtin.

**`]f`/`[f` are just `]]`/`[[`.** In kernel C the opening brace is in column 0, which is
exactly what the section motions match, and they already honour counts and already push
the jumplist, so `<C-o>` comes back. Not `]m`/`[m` — those are brace-based and Java-shaped,
and in C they land inside the function on things like `while (1) {`. Keep these `noremap`:
under `map` they would pick up each ftplugin's own `]]`, which sounds like an upgrade but
means `]f` skips every method in a Python class (python.vim puts per-def motion on `]m`,
not `]]`) and changes axis in Markdown. The buffer-local `]]` that `56-` sets in diff
buffers is invisible to `]f` for the same reason — `noremap` does not re-map the rhs.

**Mapping `[` and `]` for which-key needs `g:which_key_fallback_to_native_key = 1`.** It
defaults to 0 (`plugin/which_key.vim:25`), and at 0 an unmapped follow-key hits
`which_key#error#undefined_key()` and runs *nothing* — which silently kills every unmapped
bracket builtin (`]]`, `][`, `]#`, `]/`, `]}`, `])`, `]s`, `]z`, `]m`). Registering a plain
*string* description for such a key is safe: `s:handle_char_on_start` type-tests the value,
and a string falls through to the `elseif g:which_key_fallback_to_native_key` branch, so the
builtin still fires and still gets a label. Verified in a pty: `]]` → the col-0 brace, `]#`
→ the `#else`. `s:create_runtime()` merges the registered dict *over* the parsed native
maps, so the dicts in `30-` do not need to stay exhaustive to stay correct.

**`]i`/`[i` is indentation, not syntax, and that is the point.** It needs no parser, so one
implementation behaves the same in Python, YAML, JSON, Markdown lists, Makefiles and braced
C. It skips blank lines and lone closing delimiters, so `}` is not a peer of the statements
above it, and stops at the first line that dedents. It shadows the builtin `[i`/`]i`
(keyword lookup through `'path'` includes) — but only in normal mode, since that builtin has
no visual or operator form, and `:ilist`/`:isearch` still exist.

**`]r`/`[r` uses the LSP, not a text search.** `CocAction('symbolRanges')` returns the
documentHighlight ranges coc already computes on every `CursorHold` (`50-coc.vim:337`), so
it matches the *symbol*, not the string — a `\<ret\>` search would hit every unrelated local
plus comments and strings. Falls back to a whole-word search with no server, and either way
saves and restores `@/` so it does not clobber the search you were in the middle of.
Cost: vimtex owns `]r`/`[r` in `.tex` (next `\begin{frame}`) and yields to a pre-existing
global map, so that motion is lost there.

**Obsidian support is a port of what nvim uses, not a plugin.** obsidian.nvim is Lua, so
`80-` reimplements the subset the nvim config exercises — `:ObsidianSearch`,
`:ObsidianQuickSwitch`, `:ObsidianNew`, the three default buffer maps and the frontmatter
written on save — on fzf.vim and ripgrep, under the same command names and keys. The vault
is `g:obsidian_vault`, the same path as nvim's `workspaces`; where that directory is missing
the commands warn and the autocmds return on their first test. No language server:
markdown-oxide and marksman exist to resolve note-to-note links, and the vault has none —
every `[[…]]` in it is an image embed. Not ported, for the same reason: dailies, templates,
backlinks, tags, rename, paste-image, completion.

Deliberate differences from nvim, each marked `DIVERGES` in the file: `:ObsidianNew Title`
names the file `Title.md` (nvim's default is a Zettel id); a URL or an embed under the
cursor opens on the desktop through `g:obsidian_open_cmd` (nvim only warns on a URL, and
for an embed offers to create a note called `image.png`); frontmatter is only ever *added
to* — the block if there is none, then whichever of `id`/`aliases`/`tags` is missing —
where nvim re-serialises and re-sorts the whole block; links resolve by file name or path,
Obsidian's own rule, not by frontmatter `id` or alias; a heading anchor keeps its non-ASCII
characters; and `:ObsidianQuickSwitch arg` treats the argument as a starting query.

**`<CR>` in a vault note edits text.** It is obsidian.nvim's `smart_action`: off a link it
toggles the checkbox, and on a line that is not a task it *makes* one. nvim does the same
on the same key. The cycle is `g:obsidian_checkboxes`, nvim's default `[ ] [~] [!] [>] [x]`;
`[p]` and `[c]` are outside it and are left alone.

**The Obsidian syntax items hang off `after/syntax/markdown.vim`, not a `Syntax` autocmd.**
The autocmd passes every first test. Then one `:syntax enable` re-sources `synload.vim`,
whose `au! Syntax *` re-registers the runtime's own handler *behind* ours; from then on ours
runs first and the runtime's `syntax clear` wipes what it added. The runtime sources
`after/syntax/` itself, last, so there is no order to lose. It is the registration-order
rule the `syntaxset` block at the top of `20-` relies on, from the losing side.

**`<leader>ch` only works typed at speed**, exactly like `<leader>ca` and `<leader>cb`.
`<leader>c` is a complete map of its own (the OSC 52 operator), so once the which-key popup
is up, `c` resolves to that and the next key becomes its motion. Measured in a pty: slow
`<Space>` `c` `b` does not start Goyo, fast `<Space>cb` does. `<CR>` is the dependable key.

**The start screen's `i` is the vault search**, nvim's dashboard key. startify binds its
entries after its own keys, so the entry takes over the builtin `i` (`:enew` + insert;
`<Insert>` still does that, and `e` opens the empty buffer) — what the `s` entry already
does to the split marker, against the advice in startify's docs. `80-` appends the entry
rather than `70-` listing it: it is only wanted where the vault exists, so a machine
without one keeps the builtin, and `70-` is sourced before the vault is known.

---

## 5. Performance

Startup is ~120 ms and is treated as a budget. The big wins already taken: pinning
`g:airline_theme` (~34 ms), lazy colourschemes, deferring three plugins (~16 ms),
turning off vim-signature's periodic refresh (2.55 ms *per idle tick*), gating
context.vim's own autocmds, and dropping signify's `CursorHoldI` refresh.

Things worth knowing before "optimising":

- Most apparent big-file slowness here was **size-independent** and lived on the
  idle path. Measure before assuming.
- `:profile` times vimscript, **not** the redraw an option-set schedules. That is
  how context.vim's `'conceallevel'` toggle stayed invisible while costing ~1.8 ms
  per cursor move.
- Vimscript list allocation is expensive. A "generic" sweep over `[attr, skip]`
  pairs measured 43 ms against 15 ms for flat hardcoded checks on the same ~700
  highlight groups.

---

## 6. Testing changes

`~/.vim` is **not** version controlled. Back it up before wide edits.

Always confirm the config still sources:

```sh
vim -n -es -u ~/.vimrc -c 'qa!' </dev/null   # exit 0, no output
```

Harness traps, all hit for real:

- **`-es` (silent Ex) does not fire `VimEnter`** when stdin is at EOF, and cannot
  drive `input()` prompts (`<Esc>` aborts the script silently). Good for options,
  mappings and functions; useless for startup behaviour.
- **`-c`/`-S` commands run BEFORE `VimEnter`** (`:help VimEnter`), so a `-S` test
  script inspects and quits before any VimEnter hook fires.
- **A pty is required for anything interactive.** `script -qfc "vim …" /dev/null`
  with a `-s keyfile`; keystrokes are consumed after startup. It will **hang on
  exit** because coc keeps a `node` child on the pty — use `timeout` and read the
  result file rather than relying on a clean exit.
- **Killed test vims leave swap files** that make the next run sit on the E325
  prompt and produce plausible garbage. Run with `-n`.
- **Never `pkill -f <pattern>`** where the pattern also matches your own shell's
  command line — the shell kills itself and the run looks like a crash.
- Script-local functions are reachable as `<SNR>N_Name`; resolve `N` by scanning
  `scriptnames` **line by line**. A single `matchstr` over the whole output returns
  the wrong number, and `function('<SNR>1_Foo')` only fails when *called*, so every
  assertion silently no-ops while the test still prints plausible output.
- When touching highlights, assert that groups still **have** a colour. An audit
  that only checks resolved attributes reports a clean "0 bold, 0 italic" while
  links are already destroyed. Test against Vim's built-ins (`koehler`, `desert`,
  `elflord`, `industry`), which lean hardest on default links.

Text objects and mappings add their own traps, all hit for real:

- **`:normal!` bypasses omap/xmap.** A test written as `normal! daf` silently exercises
  Vim's *builtins* and passes vacuously. Drop the bang. Also never bar-chain after
  `:normal` — it swallows the rest of the line including the `|`.
- **Assert into a named register.** `20-mappings.vim` lists the unnamed register in
  `s:osc_yank_regs`, so a plain `yaf` in a test sprays OSC 52 escape bytes into stdout.
  Use `"zy…` plus `getreg('z')` / `getregtype('z')` — the regtype is how you catch a
  charwise/linewise mismatch.
- **`maparg()` is the wrong probe for bracket keys.** It cannot see builtins (`]c` in
  diff mode looks free but is not), and under `-es` it cannot see vim-unimpaired at all,
  because `95-` defers it to `SafeState` and `-es` never gets there. A headless collision
  audit reports every contested key as free. Force `plug#load('vim-unimpaired')` first.
- **The jumplist dedups.** Testing a motion from line 1 shows no growth when line 1 is
  already the top entry, which reads as "this motion doesn't set jumps". Start from a
  line that is not already on the list, and assert on where `<C-o>` lands.
- **Anything coc-backed needs a pty**, and the obvious readiness probe lies:
  `exists('*CocAction')` and `g:did_coc_loaded` are both true under `-es` while the node
  service never started, so calls throw `coc.nvim not ready`. Split the suite — `-es` for
  builtins and pure vimscript, `script -qfc` with a `timer_start` delay for LSP paths.
- **targets.vim's `ia`/`aa` is a silent no-op under `-es`** even though its siblings
  (`ab`, `i(`, `iB`) work, because `targets#e()` reads keys with `getchar()`. A headless
  `@parameter` suite goes green while proving nothing.
- **which-key needs a pty too**, for the same `getchar()` reason. To check that a bracket
  builtin survived, drive it with `script -qfc "vim -n -u ~/.vimrc -s keys.in file"` and a
  keyfile of literal keystrokes, then assert on a variable you set from the keyfile.
- **Check the fixture before believing a failure.** A `2]r` assertion here "failed" only
  because two `kern.c` fixtures differed by one line; the code was right. Re-read the file
  under test before changing code to satisfy a test.

`80-obsidian.vim` added more, all hit for real:

- **Never point a test at the real vault.** `:w` there rewrites frontmatter and Dropbox
  syncs it. `80-` reads its settings with `get()`, so a fixture is two flags:
  `--cmd "let g:obsidian_vault='/path/to/fixture'"` and
  `--cmd "let g:obsidian_open_cmd=['/path/to/log-args.sh']"` — the second keeps a followed
  link from opening a browser.
- **`:normal` cannot start with a space**, and `mapleader` is Space. `execute "normal
  \<Space>ch"` therefore runs `ch` — nothing in column 1, a deleted character anywhere
  else — and the failure reads as a broken mapping. Use `call feedkeys("\<Space>ch", 'tx')`.
- **A `Syntax` autocmd is not tested until `:syntax enable` has run a second time.** See §4.
- **More than ten `-c`/`--cmd` arguments is a hard error** ("Too many +command"). Put the
  script in a file and `-S` it.
- **`:edit! file` discards the *current* buffer's changes, not the target's.** A hidden,
  modified target comes back with its edits. Reloading from disk is `:edit file`, then a
  bare `:edit!`.
- **fzf needs time that a `-s keyfile` cannot give it.** `script` forwards stdin, so pace
  the keys: `( sleep 3; printf ':ObsidianSearch\r'; sleep 3; printf 'query'; sleep 3;
  printf '\r'; … ) | script -qfc "…" /dev/null`, setting the size first with
  `stty rows 50 cols 160`. With `--cmd 'let g:coc_start_at_startup=0'` the run also exits
  on its own instead of hanging on coc's `node`.
- **`redir` around `:colorscheme` blames the theme for this config's noise.** `silent!`
  hides an error from the screen, not from `redir`, so the `silent! unlet
  g:indentLine_color_*` pair in `30-` shows up as two `E108` for every theme that does not
  set those variables — koehler and nord as much as a new one. Compare against a theme
  already installed before reading a captured message as the new theme's.

---

## 7. Terminal

`~/.tmux.conf` sets `default-terminal "tmux-256color"` and `allow-passthrough on`.

Both matter: `screen-256color` has no `sitm`, so Vim emits **SGR 7 (reverse video)**
for italic — every italic group renders as a solid slab, which is not a theme bug.
And without passthrough, yazi's second startup probe can never be answered and it
burns a full second on a DA1 timeout.

`default-terminal` needs `tmux source-file` **plus a new window**;
`allow-passthrough` applies immediately.
