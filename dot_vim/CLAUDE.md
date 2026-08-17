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
| `60-coc-semantic.vim` | theme-adaptive LSP semantic-token colours |
| `70-sessions-startify.vim` | sessions and the start screen |
| `90-config-edit.vim` | `:Vimrc`, `:VimrcGrep` |
| `95-deferred-plugins.vim` | idle-time loading of `{'on': []}` plugins. **Must be last** |

Also: `autoload/airline/extensions/tabline/formatters/parentfile.vim` (tabline
format — must live at that path, airline resolves formatters by autoload name),
`coc-settings.json`, `bin/sy-diff.sh` (signify wrapper for untracked files).

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
(nvim uses LazyVim's `<leader><tab>d`), visual `*`/`#`, `<Leader>:`.

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

**Windows / tabs / buffers** `<C-h/j/k/l>` navigate (tmux-aware) · `<C-arrow>`
resize · `<Tab>`/`<S-Tab>` cycle buffers · `]t`/`[t` tabs · `<leader>tc` close tab ·
`<leader>x` / `<leader>bd` close buffer · `<leader>op`/`<leader>pp` quickfix

**Bookmarks** `<leader>ha` toggle · `<leader>hh` list · `<leader>hn`/`<leader>hp`
next/prev · `<leader>hc`/`<leader>hx` clear. In the list: `1-9` jump, `i` annotate,
`dd` delete, `K`/`J` reorder.

**Misc** `<leader>th` theme picker · `<leader>ve` edit config · `<leader>vg` grep
config · `<C-s>` yazi · `<C-g>` floaterm · `<leader>lg` lazygit · `<leader>c` OSC 52
yank · `*`/`#` in visual mode search the selection

**Commands** `:Vimrc[!]` `:VimrcGrep` `:Session` `:SessionLoad` `:Format` `:Fold`
`:OR` `:Inspect` `:SemCheck` `:HistoryCwd` `:AsyncTaskFzf` `:WQ` `:W`

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

**Sessions** are one file per project in `~/.local/state/vim/sessions`, named from
the cwd. `:Session` once per project; after that it loads on entry (VimEnter) and
rewrites on exit. Persistence writes only at `VimLeavePre`, so a SIGKILL loses the
session's changes. The start screen is wiped before saving — a session containing a
startify buffer fails to restore (`E121: g:startify_header`).

**Signs** come from vim-signify over git *and hg* (fbsource is Sapling), through
`bin/sy-diff.sh` so untracked files show as all-added.

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

---

## 7. Terminal

`~/.tmux.conf` sets `default-terminal "tmux-256color"` and `allow-passthrough on`.

Both matter: `screen-256color` has no `sitm`, so Vim emits **SGR 7 (reverse video)**
for italic — every italic group renders as a solid slab, which is not a theme bug.
And without passthrough, yazi's second startup probe can never be answered and it
burns a full second on a DA1 timeout.

`default-terminal` needs `tmux source-file` **plus a new window**;
`allow-passthrough` applies immediately.
