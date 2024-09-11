" Don't try to be vi compatible
set nocompatible

" Helps force plugins to load correctly when it is turned back on below
filetype off

" https://github.com/junegunn/vim-plug
" TODO: Load plugins here (pathogen or vundle)
call plug#begin()
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes

Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround' 
Plug 'vim-airline/vim-airline'
Plug 'github/copilot.vim', { 'as': 'copilot' }
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'lervag/vimtex'
Plug 'lervag/vimtex', { 'tag': 'v2.15' }
Plug 'yggdroot/indentline'
Plug 'terryma/vim-smooth-scroll'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-commentary'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'easymotion/vim-easymotion'
Plug 'mhinz/vim-startify'
Plug 'chrismccord/bclose.vim', {'as': 'bclose'}
Plug 'farmergreg/vim-lastplace'
Plug 'raimondi/delimitmate'
Plug 'romainl/vim-cool'
Plug 'voldikss/vim-floaterm'
Plug 'junegunn/goyo.vim'
Plug 'jdhao/better-escape.vim'
Plug 'wellle/targets.vim'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
"
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'piec/vim-lsp-clangd'
" Plug 'octol/vim-cpp-enhanced-highlight'
" Plug 'bfrg/vim-cpp-modern'

Plug 'morhetz/gruvbox' 
Plug 'lifepillar/vim-solarized8'
Plug 'rose-pine/vim', { 'as': 'rose-pine' }
Plug 'nordtheme/vim', { 'as': 'nord' }
Plug 'catppuccin/vim', { 'as': 'catppuccin' }
Plug 'sainnhe/gruvbox-material'
Plug 'sainnhe/everforest'
Plug 'junegunn/seoul256.vim'

" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()

" ---------------------------------------MAPPING-----------------------------------

" Turn on syntax highlighting
syntax on
" For plugins to load correctly
filetype plugin indent on
:autocmd InsertEnter * set cursorline
:autocmd InsertLeave * set nocursorline

" Pick a leader key
let mapleader = " "
let maplocalleader = "\\"
nnoremap <SPACE> <Nop>
nnoremap <Leader>cl :cclose<CR>
command! W write

" Edit operation
nnoremap j gj
nnoremap k gk
nnoremap <C-q> <Home>
nnoremap <C-e> <End>
inoremap <C-h> <left>
inoremap <C-j> <down>
inoremap <C-k> <up>
inoremap <C-l> <right>
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <Leader>x :Bclose<CR>
nnoremap <Leader>bd :Bclose<CR>
nnoremap <C-a> ggVG
nnoremap <C-c> "+y
nnoremap <C-p> "+p

" -----------------------------PLUGIN CONFIG-----------------------------------
"  mapping
nnoremap gd :LspDefinition<CR>
nnoremap gD :LspDeclaration<CR>
nnoremap K :LspHover<CR>
nnoremap pd :LspPeekDefinition<CR>
nnoremap pD :LspPeekDeclaration<CR>
nnoremap rn :LspRename<CR>
nnoremap ol :LspWorkspaceSymbol<CR>
nnoremap ca :LspCodeAction<CR>
nnoremap ic :LspCallHierarchyIncoming<CR>
nnoremap oc :LspCallHierarchyOutgoing<CR>
nnoremap <Leader>fm :LspDocumentFormat<CR>
nnoremap ]g :LspNextDiagnostic<CR>
nnoremap [g :LspPreviousDiagnostic<CR>
" better escape
let g:better_escape_shortcut = ['jk', 'jj']

"  goyo
let g:goyo_width = 85
let g:goyo_height = 100
let g:goyo_linenr = 1
nnoremap <silent> <Leader>cb :Goyo<CR>

" tmux navigator
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-h> :<C-U>TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :<C-U>TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :<C-U>TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :<C-U>TmuxNavigateRight<cr>

" smooth scroll
noremap <silent> <c-u> :call smooth_scroll#up(&scroll, 0, 2)<CR>
noremap <silent> <c-d> :call smooth_scroll#down(&scroll, 0, 2)<CR>
noremap <silent> <c-b> :call smooth_scroll#up(&scroll*2, 0, 4)<CR>
noremap <silent> <c-f> :call smooth_scroll#down(&scroll*2, 0, 4)<CR>

" vimtex
let g:vimtex_view_method = 'sioyek'
let g:vimtex_quickfix_open_on_warning = 0
let g:vimtex_syntax_conceal_disable = 1

" copilot
let g:copilot_no_tab_map = v:true
imap <silent><script><expr> <C-space> copilot#Accept("\<CR>")

" air line
let g:airline#extensions#tabline#enabled = 1
let g:airline_left_sep='>'
let g:airline#extensions#whitespace#enabled = 0
au VimEnter * let [g:airline_section_y] = [airline#section#create([''])]

" git operation
nnoremap <Leader>git :Git<CR>

" fzf
nnoremap <Leader>ff :GFiles ${PWD}<CR>
nnoremap <Leader>fl :Files 
nnoremap <Leader>fw :Rg 
nnoremap <Leader>th :Colors<CR>
nnoremap <Leader>bf :Buffers<CR>
nnoremap <Leader>jp :Jumps<CR>

" cpp highlight
" let g:cpp_class_scope_highlight = 1
" let g:cpp_member_variable_highlight = 1
" let g:cpp_class_decl_highlight = 1
" let g:cpp_posix_standard = 1
" let g:cpp_experimental_simple_template_highlight = 1
" let g:cpp_concepts_highlight = 1
" let g:cpp_function_highlight = 1
" let g:cpp_attributes_highlight = 1
" let g:cpp_member_highlight = 1
" let g:cpp_simple_highlight = 1

" float term
let g:floaterm_keymap_new    = '<F1>'
let g:floaterm_keymap_prev   = '<F2>'
let g:floaterm_keymap_next   = '<F3>'
let g:floaterm_keymap_kill   = '<F4>'
let g:floaterm_keymap_toggle = '<F12>'

" Nerd tree
nnoremap <C-s> :NERDTreeToggle<CR>
autocmd FileType nerdtree map <buffer> h u
autocmd FileType nerdtree map <buffer> l <CR>

" easy motion
let g:EasyMotion_smartcase = 1
let g:EasyMotion_no_mapping = 0
" autocmd User EasyMotionPromptBegin :let b:coc_diagnostic_disable = 1
" autocmd User EasyMotionPromptEnd :let b:coc_diagnostic_disable = 0

" map <Leader> <Plug>(easymotion-prefix)
map  f <Plug>(easymotion-fl)
map  F <Plug>(easymotion-Fl)
map  t <Plug>(easymotion-tl)
map  T <Plug>(easymotion-Tl)
nmap s <Plug>(easymotion-overwin-f2)
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)

" -------------------------------VIM CONFIG---------------------------------
" Swap file
set directory^=$HOME/.vim/swap//

" Security
set modelines=0

" Show line numbers
set number

" Show file stats
set ruler
set relativenumber

" Encoding
set encoding=utf-8

" Folding
" set foldmethod=expr
"   \ foldexpr=lsp#ui#vim#folding#foldexpr()
"   \ foldtext=lsp#ui#vim#folding#foldtext()
" set nofoldenable
" nnoremap <leader>z :set foldenable!<CR>

" Whitespace
set wrap
set textwidth=80
set formatoptions=tcqrn1
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set noshiftround

" Cursor motion
set scrolloff=3
set backspace=indent,eol,start
set belloff=all
set timeoutlen=400
set ttimeoutlen=400
set matchpairs+=<:> " use % to jump between pairs
runtime! macros/matchit.vim

" Allow hidden buffers
set hidden

" Rendering
set ttyfast
set guicursor+=a:blinkon0

" Status bar
set laststatus=2

" Last line
set showmode
set showcmd

" Searching
set hlsearch
set incsearch
set smartcase
set showmatch

" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬

" auto read file when changed
set autoread
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
autocmd FileChangedShellPost *
            \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

" -----------------------------------COLOR SCHEME-----------------------------------
"  set highlight color
set background=dark
syntax match BugKeyword /BUG:/
highlight link BugKeyword ErrorMsg
syntax match NoteKeyword /NOTE:/
highlight link NoteKeyword DiffAdd
syntax match WarnKeyword /WARN:/
highlight link WarnKeyword DiffText
syntax match PerfKeyword /PERF:/
highlight link PerfKeyword DiffText
syntax match PARAKeyword /PARA:/
highlight link PARAKeyword DiffChange

" Color scheme (terminal)
let g:gruvbox_bold = 0
colorscheme gruvbox

" use gruvbox in default 256 color
augroup ColorSchemeSettings
    autocmd!
    autocmd ColorScheme * if g:colors_name == 'gruvbox' | set t_Co=256 | else | set termguicolors | endif
augroup END

" use nord for better color in latex (gruvbox is not good for latex)
augroup LaTeXColorScheme
    autocmd!
    autocmd FileType tex bib colorscheme nord
    autocmd FileType tex bib let g:indentLine_setConceal = 0
augroup END

" kill both floaterm and nerdtree when only they exists
function! s:kill_all_floaterm() abort
    for bufnr in floaterm#buflist#gather()
        call floaterm#terminal#kill(bufnr)
    endfor
    return
endfunction
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree()  | call s:kill_all_floaterm() | quit | endif
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call s:kill_all_floaterm() | quit | endif

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

" ---------------------------------------COC---------------------------------------------
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"
let g:asycomplete_max_items = 10
if executable('clangd')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'clangd',
        \ 'cmd': {server_info->['clangd', '-background-index']},
        \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp'],
        \ })
endif
if executable('bash-language-server')
  augroup LspBash
    autocmd!
    autocmd User lsp_setup call lsp#register_server({
          \ 'name': 'bash-language-server',
          \ 'cmd': {server_info->[&shell, &shellcmdflag, 'bash-language-server start']},
          \ 'allowlist': ['sh'],
          \ })
  augroup END
endif
if executable('pyls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pyls',
        \ 'cmd': {server_info->['pyls']},
        \ 'whitelist': ['python'],
        \ })
endif
autocmd BufWritePre *.sh,*.py,*.c,*.cpp LspDocumentFormat
let g:lsp_semantic_enabled = 1 
autocmd ColorScheme * highlight link LspSemanticVariable Variable
autocmd ColorScheme * highlight link LspSemanticParameter Parameter
autocmd ColorScheme * highlight link LspSemanticConcept Macro
autocmd ColorScheme * highlight link Readonly Number

let g:lsp_diagnostics_virtual_text_align = "right"
" -----------------------------STARTIFY-----------------------------------
let g:startify_commands = [
            \ {'g': ['Git status', 'Git']},
            \ {'f': ['Files', 'GFiles ${PWD}']},
            \ {'s': ['Edit .vimrc', 'e $MYVIMRC']},
            \ ]
let g:startify_lists = [
            \ { 'type': 'files',     'header': ['   Recent']            },
            \ { 'type': 'commands',  'header': ['   Commands']       },
            \ ]
let g:startify_change_to_dir = 0
" let g:startify_custom_header = g:ascii + startify#fortune#boxed()
let g:startify_files_number = 6
