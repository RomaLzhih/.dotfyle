" 00-plugins.vim -- the vim-plug list. Must be sourced first.

" source $LOCAL_ADMIN_SCRIPTS/master.vimrc

set nocompatible
filetype off

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-surround'
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-fuzzy.vim'
Plug 'haya14busa/incsearch-easymotion.vim'
Plug 'vim-airline/vim-airline'
Plug 'chriszarate/yazi.vim'
" Deferred: ~100 bracket maps, no autocmds, nothing here references it.
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
" Deferred: VM builds its own default maps, so a <Plug> whitelist would drop most.
Plug 'mg979/vim-visual-multi', {'branch': 'master', 'on': []}
" Deferred AND <Plug>-triggered: triggers keep f/F/t/T correct during type-ahead;
" the deferred load covers the `/` incsearch path, which bypasses every <Plug> map.
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
Plug 'bfrg/vim-qf-preview', { 'for': 'qf' }
Plug 'wellle/context.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'preservim/vim-markdown'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'mhinz/vim-signify'

" Only the active scheme loads eagerly; the rest are {'on': []} to keep 15 dirs out
" of the startup rtp scan. The ColorSchemePre hook in 30- loads one on demand, so
" `:colorscheme nord` and <leader>th still work. Native <Tab> completion only lists
" loaded schemes.
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
Plug 'ku1ik/vim-monokai', { 'on': [] }
Plug 'nanotech/jellybeans.vim', { 'on': [] }
Plug 'embark-theme/vim', { 'as': 'embark', 'on': [] }
Plug 'srcery-colors/srcery-vim', {'on': []}
Plug 'EdenEast/nightfox.nvim', {'on': []}
Plug 'lunacookies/vim-colors-xcode', {'on': []}

" Also runs `filetype plugin indent on` and `syntax enable`.
call plug#end()
