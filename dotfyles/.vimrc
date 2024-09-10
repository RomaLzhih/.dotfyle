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
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'romainl/vim-cool'
Plug 'voldikss/vim-floaterm'
Plug 'junegunn/goyo.vim'
Plug 'jdhao/better-escape.vim'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'bfrg/vim-cpp-modern'

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
" better escape
let g:better_escape_shortcut = ['jk', 'jj']

"  goyo
let g:goyo_width = 85
let g:goyo_height = 100
let g:goyo_linenr = 1
nnoremap <silent> <Leader>zm :Goyo<CR>

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
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_posix_standard = 1
let g:cpp_experimental_simple_template_highlight = 1
let g:cpp_concepts_highlight = 1
let g:cpp_function_highlight = 1
let g:cpp_attributes_highlight = 1
let g:cpp_member_highlight = 1
let g:cpp_simple_highlight = 1

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
autocmd User EasyMotionPromptBegin :let b:coc_diagnostic_disable = 1
autocmd User EasyMotionPromptEnd :let b:coc_diagnostic_disable = 0

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
" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup
" Give more space for displaying messages.
set cmdheight=1
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300
" Don't pass messages to |ins-completion-menu|.
set shortmess+=c
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
    " Recently vim can merge signcolumn and number column into one
    set signcolumn=number
else
    set signcolumn=yes
endif
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <silent><expr> <TAB>
            \ coc#pum#visible() ? coc#pum#next(1):
            \ exists('b:_copilot.suggestions') ? copilot#Accept("\<CR>") :
            \ CheckBackSpace() ? "\<Tab>" :
            \ coc#refresh()
" Use <c-space> to trigger completion.
" if has('nvim')
"     inoremap <silent><expr> <c-space> coc#refresh()
" else
" endif
" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
            \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>
let g:coc_global_extensions = ['coc-clangd', 'coc-sh', 'coc-diagnostic', 'coc-highlight']
" let g:coc_default_semantic_highlight_groups = 1
" let hlMap = {
"             \ 'Namespace': 'Include',
"             \ 'Type': 'Type',
"             \ 'Class': 'Special',
"             \ 'Enum': 'Class',
"             \ 'Interface': 'Type',
"             \ 'Struct': 'Structure',
"             \ 'TypeParameter': 'Parameter',
"             \ 'TypeTypeParameter': 'Type',
"             \ 'TypeType': 'Type',
"             \ 'TypeVariable': 'Variable',
"             \ 'TypeConcept': 'Constant',
"             \ 'TypeUnknown': 'Identifier',
"             \ 'TypeMethod': 'Function',
"             \ 'TypeClass': 'Special',
"             \ 'TypeProperty': 'Identifier',
"             \ 'TypeFunction': 'Function',
"             \ 'TypeMacro': 'Define',
"             \ 'TypeNamespace': 'Include',
"             \ 'Parameter': 'Parameter',
"             \ 'Variable': 'Variable',
"             \ 'Property': 'Identifier',
"             \ 'EnumMember': 'Constant',
"             \ 'Event': 'Keyword',
"             \ 'Function': 'Function',
"             \ 'Method': 'Function',
"             \ 'Macro': 'Define',
"             \ 'Keyword': 'Keyword',
"             \ 'Modifier': 'StorageClass',
"             \ 'Comment': 'Comment',
"             \ 'String': 'String',
"             \ 'Number': 'Number',
"             \ 'Boolean': 'Boolean',
"             \ 'Regexp': 'String',
"             \ 'Operator': 'Operator',
"             \ 'Decorator': 'Identifier',
"             \ 'Deprecated': 'CocDeprecatedHighlight'
"             \ }
" for [key, value] in items(hlMap)
"     execute 'hi default link CocSem'.key.' '.(value)
" endfor

" Hover
function! s:show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
    elseif (coc#rpc#ready())
        call CocActionAsync('doHover')
    else
        execute '!' . &keywordprg . " " . expand('<cword>')
    endif
endfunction
" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')
" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>inlay :CocCommand document.toggleInlayHint
" Formatting selected code.
xmap <leader>fm  <Plug>(coc-format)
nmap <leader>fm  <Plug>(coc-format)

augroup mygroup
    autocmd!
    " Setup formatexpr specified filetype(s).
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ca  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
    nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
    nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
    inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
    inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
    vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
    vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
" nmap <silent> <C-s> <Plug>(coc-range-select)
" xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>sbd  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>coce  :<C-u>CocList extensions<cr>
" Show commands.
" nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <Leader>ol  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>sym  :<C-u>CocList -I symbols<cr>

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
