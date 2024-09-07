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
Plug 'vim-airline/vim-airline-themes'
Plug 'github/copilot.vim'
Plug 'junegunn/fzf'
Plug 'tpope/vim-fugitive'
Plug 'vim-scripts/greplace.vim'
Plug 'lervag/vimtex'
Plug 'lervag/vimtex', { 'tag': 'v2.15' }
Plug 'yggdroot/indentline'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-commentary'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'easymotion/vim-easymotion'
Plug 'junegunn/fzf.vim'
Plug 'mhinz/vim-startify'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'raimondi/delimitmate'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'bfrg/vim-cpp-modern'
Plug 'voldikss/vim-floaterm'

Plug 'morhetz/gruvbox' 
Plug 'ericbn/vim-solarized'
Plug 'rose-pine/vim', { 'as': 'rose-pine' }
Plug 'nordtheme/vim', { 'as': 'nord' }
Plug 'catppuccin/vim', { 'as': 'catppuccin' }

" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()
" You can revert the settings after the call like so:
"   filetype indent off   " Disable file-type-specific indentation
"   syntax off            " Disable syntax highlighting
" Turn on syntax highlighting
syntax on
" For plugins to load correctly
filetype plugin indent on

" Pick a leader key
let mapleader = " "
let maplocalleader = "\\"
nnoremap <SPACE> <Nop>
nnoremap <Leader>cl :cclose<CR>

" Edit operation

nnoremap <C-q> <Home>
nnoremap <C-e> <End>
inoremap <C-h> <left>
inoremap <C-j> <down>
inoremap <C-k> <up>
inoremap <C-l> <right>
inoremap jk <Esc>
inoremap jj <Esc>
nnoremap <Tab> :bnext<CR>
nnoremap <Leader>x :bd<CR>

" tmux navigator
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-h> :<C-U>TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :<C-U>TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :<C-U>TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :<C-U>TmuxNavigateRight<cr>

" vimtex
let g:vimtex_view_method = 'sioyek'
let g:vimtex_quickfix_open_on_warning = 0
let g:vimtex_syntax_conceal_disable = 1

" copilot
let g:copilot_no_tab_map = v:true

" indent line
let g:indentLine_setConceal = 0

" air line
let g:airline#extensions#tabline#enabled = 1
let g:airline_left_sep='>'
let g:airline#extensions#whitespace#enabled = 0
au VimEnter * let [g:airline_section_y] = [airline#section#create([''])]

" git operation
nnoremap <Leader>git :Git<CR>

" fzf
nnoremap <Leader>ff :Files .<CR>
nnoremap <Leader>re :Files 
nnoremap <Leader>fw :Rg 
nnoremap <Leader>th :Colors<CR>
nnoremap <Leader>bf :Buffers<CR>

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
let g:floaterm_keymap_toggle = '<C-\>'

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

" Move up/down editor lines
nnoremap j gj
nnoremap k gk

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
" nnoremap / /\v
" vnoremap / /\v
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
nnoremap <leader><space> :let @/=''<cr> " clear search

" Remap help key.
nnoremap <C-a> ggVG
nnoremap <C-c> "+y
nnoremap <C-p> "+p

" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬
" Uncomment this to enable by default:
" set list " To enable by default
" Or use your leader key + l to toggle on/off

" Color scheme (terminal)
" set t_Co=256
" set termguicolors
set background=dark
autocmd ColorScheme * call Highlight()
function! Highlight() abort
  hi Conceal ctermfg=239 guifg=#504945
  hi CocSearch ctermfg=12 guifg=#18A3FF
endfunction
autocmd vimenter * ++nested colorscheme gruvbox
" colorscheme solarized
colorscheme gruvbox
augroup ColorSchemeSettings
    autocmd!
    autocmd ColorScheme * if g:colors_name == 'gruvbox' | set t_Co=256 | else | set termguicolors | endif
augroup END
augroup LaTeXColorScheme
    autocmd!
    autocmd FileType tex colorscheme nord
augroup END
function! s:kill_all_floaterm() abort
    for bufnr in floaterm#buflist#gather()
      call floaterm#terminal#kill(bufnr)
    endfor
    return
endfunction

autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree()  | call s:kill_all_floaterm() | quit | endif
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call s:kill_all_floaterm() | quit | endif

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
" inoremap <silent><expr> <TAB>
"             \ pumvisible() ? "\<C-n>" :
"             \ <SID>check_back_space() ? "\<TAB>" :
"             \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1):
      \ exists('b:_copilot.suggestions') ? copilot#Accept("\<CR>") :
      \ CheckBackSpace() ? "\<Tab>" :
      \ coc#refresh()


" Use <c-space> to trigger completion.
if has('nvim')
    inoremap <silent><expr> <c-space> coc#refresh()
else
    inoremap <silent><expr> <c-@> coc#refresh()
endif

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
let g:coc_user_config={
            \    'suggest.maxCompleteItemCount': 10,
            \    'coc.preferences.formatOnSaveFiletypes': ["cpp", "sh", "bash", "python"],
            \    'colors.enable': 'true',
            \    'outline.autoPreview': 'true',
            \}
let g:coc_global_extensions = ['coc-clangd', 'coc-git', 'coc-sh', 'coc-pyright', 'coc-cmake', 'coc-diagnostic', 'coc-highlight', 'coc-lightbulb', 'coc-symbol-line', 'coc-texlab']

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
" Do default action for next item.
" nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
" nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
" nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
"
" -----------------------------STARTIFY-----------------------------------
let g:startify_commands = [
    \ {'g': 'Git'},
    \ {'f': 'Files .'},
    \ {'s': 'e $MYVIMRC'},
    \ ]
let g:startify_lists = [
          \ { 'type': 'files',     'header': ['   Recent']            },
          \ { 'type': 'commands',  'header': ['   Commands']       },
          \ ]
let g:startify_change_to_dir = 1
" let g:startify_custom_header = g:ascii + startify#fortune#boxed()
let g:startify_files_number = 5
" -- let g:startify_session_persistence= 1
