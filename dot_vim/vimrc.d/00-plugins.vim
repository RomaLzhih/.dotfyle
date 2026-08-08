" ============================================================================
" 00-plugins.vim
" ----------------------------------------------------------------------------
" vim-plug block: the plugin list. Must be sourced first -- everything
" else configures plugins registered here.
" Sourced from ~/.vimrc. Script-local (s:) items are file-scoped: keep every
" s: function together with its callers and <SID> mappings in this file.
" ============================================================================

" source $LOCAL_ADMIN_SCRIPTS/master.vimrc

" Don't try to be vi compatible
set nocompatible

" Helps force plugins to load correctly when it is turned back on below
filetype off

" https://github.com/junegunn/vim-plug
" TODO: Load plugins here (pathogen or vundle)
call plug#begin('~/.vim/plugged')
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes

" Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround' 
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-fuzzy.vim'
Plug 'haya14busa/incsearch-easymotion.vim'
Plug 'vim-airline/vim-airline'
Plug 'chriszarate/yazi.vim'
" Deferred (see 95-deferred-plugins.vim): ~100 default bracket maps, no autocmds,
" nothing in the config references it -- so there is no command or <Plug> to
" trigger on. Loaded once Vim is idle instead.
Plug 'tpope/vim-unimpaired', { 'on': [] }
Plug 'junegunn/vim-peekaboo'
Plug 'github/copilot.vim', { 'as': 'copilot' }
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'lervag/vimtex', { 'tag': 'v2.15' }
Plug 'yggdroot/indentline'
Plug 'psliwka/vim-smoothie'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-commentary'
Plug 'brooth/far.vim'
" Deferred: VM builds its own default maps (<C-n>, <C-Down>, the \\ family) in
" vm#maps#default, so a <Plug> whitelist would silently drop most entry points.
Plug 'mg979/vim-visual-multi', {'branch': 'master', 'on': []}
" Deferred AND <Plug>-triggered: the five triggers make f/F/t/T/s correct even
" during type-ahead; the deferred load covers the `/` incsearch path, which
" reaches EasyMotion#go() without going through any <Plug> map.
Plug 'easymotion/vim-easymotion', { 'on': [
      \ '<Plug>(easymotion-fl)', '<Plug>(easymotion-Fl)',
      \ '<Plug>(easymotion-tl)', '<Plug>(easymotion-Tl)',
      \ '<Plug>(easymotion-overwin-f2)'] }
Plug 'mhinz/vim-startify'
Plug 'chrismccord/bclose.vim', {'as': 'bclose', 'on': 'Bclose'}
Plug 'farmergreg/vim-lastplace'
Plug 'raimondi/delimitmate'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'romainl/vim-cool'
Plug 'voldikss/vim-floaterm'
Plug 'junegunn/goyo.vim', {'on': 'Goyo'}
Plug 'wellle/targets.vim'
Plug 'skywind3000/asyncrun.vim'
Plug 'skywind3000/asynctasks.vim'
Plug 'liuchengxu/vim-which-key'
Plug 'ojroques/vim-oscyank', {'branch': 'main'}
Plug 'ryanoasis/vim-devicons'
Plug 'tpope/vim-sleuth'
Plug 'kshenoy/vim-signature'
Plug 'tpope/vim-repeat'
" Quickfix preview popup: press p on a quickfix entry to see it in a popup without
" leaving the list (the nvim config's nvim-bqf equivalent). Mapped in 20-mappings.vim.
"
" This plugin is already lazy by construction -- it ships no plugin/ directory, only
" autoload/ and after/ftplugin/qf.vim, so nothing is sourced until a quickfix window
" exists (measured: qfpreview#Open is undefined at startup, and startup is unchanged
" with or without the 'for'). The 'for' is kept as intent + insurance should it ever
" grow a plugin/ file; it is NOT what makes it lazy. 'for' rather than 'on' because
" plug.vim's s:lod_ft skips s:dobufread, avoiding the spurious `doautocmd BufRead`
" that makes vim-lastplace jump the cursor.
Plug 'bfrg/vim-qf-preview', { 'for': 'qf' }
" Sticky context header: pins the enclosing function/if/loop lines at the top of the
" window while scrolling -- the nvim config's nvim-treesitter-context equivalent.
" Pure vimscript, indentation-based rather than tree-based, which for C/C++/Python/Lua
" produces nearly the same header. Eager on purpose: it has to hook the scroll events
" to be "sticky" at all. Settings (presenter, large-file gate) live in
" 30-plugin-config.vim -- nvim disables it past 2000 lines for scroll jank on big C++
" (lua/plugins/others.lua:224-232), and that gate is mirrored there.
Plug 'wellle/context.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'preservim/vim-markdown'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'mhinz/vim-signify'

" Only the active scheme is loaded eagerly. The rest are registered {'on': []}:
" installed and :PlugUpdate-able, but off 'runtimepath' until wanted, which keeps
" 15 dirs out of every rtp scan at startup. The ColorSchemePre hook in
" 30-plugin-config.vim puts the owning plugin back before Vim looks for
" colors/<name>.vim, so plain `:colorscheme nord` and <leader>th still work.
" Caveat: native `:colorscheme <Tab>` completion only lists loaded schemes (the
" <leader>th picker lists all of them); `:help` for a lazy scheme needs it loaded.
Plug 'morhetz/gruvbox'
Plug 'sainnhe/gruvbox-material', { 'on': [] }
Plug 'rose-pine/vim', {'as': 'rose-pine', 'on': [] }
Plug 'nordtheme/vim', {'as': 'nord', 'on': [] }
Plug 'lifepillar/vim-solarized8', { 'on': [] }
Plug 'catppuccin/vim', { 'as': 'catppuccin', 'on': [] }
Plug 'sainnhe/everforest', { 'on': [] }
Plug 'w0ng/vim-hybrid', { 'on': [] }
Plug 'NLKNguyen/papercolor-theme', { 'on': [] }
Plug 'tomasiser/vim-code-dark', { 'on': [] }
Plug 'haishanh/night-owl.vim', { 'on': [] }
Plug 'jacoborus/tender.vim', { 'on': [] }
Plug 'bluz71/vim-moonfly-colors', { 'on': [] }
Plug 'ku1ik/vim-monokai', { 'on': [] }
Plug 'nanotech/jellybeans.vim', { 'on': [] }
Plug 'embark-theme/vim', { 'on': [] }

" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()

