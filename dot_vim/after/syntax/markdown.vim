" after/syntax/markdown.vim -- Obsidian additions on top of vim-markdown.
" Only the hook lives here; the items and the reason for this path are in
" ~/.vim/vimrc.d/80-obsidian.vim (ObsidianSyntax).
if exists('*ObsidianSyntax')
  call ObsidianSyntax()
endif
