" line number configuration
set number					" show line numbers
set relativenumber				" show line numbers relative to current line
set hidden

" tab should insert two spaces
set expandtab
set tabstop=2
set shiftwidth=2

" turn off vi 'compatible' mode
set nocompatible

" enable backspacing at beginning of line
set backspace=indent,eol,start

" netrw configuration
set nocp
filetype plugin on

" search configuration
set hlsearch					" highlight matching phrases when searching
set incsearch					" highlight search pattern while typing
nnoremap <esc><esc> :nohlsearch<return><esc>	" map <esc><esc> to disable search highlight


" colorscheme configuration
colorscheme elflord

" use unnamed register for clipboard data
set clipboard=unnamed

" vim.plug configuration
call plug#begin()
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'pearofducks/ansible-vim'
Plug 'hashivim/vim-terraform'
call plug#end()

" coc-ansible configuration
let g:coc_filetype_map = { 'yaml.ansible': 'ansible' }

" Use <CR> to confirm autocompletion
inoremap <expr> <cr> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"

" Use <Tab> and <S-Tab> to navigate the autocompletion list
inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved
set signcolumn=yes

"" netrw config
" set netrw liststyle type to tree view
let g:netrw_liststyle = 3
" size of window
let g:netrw_winsize = 25
" remove the banner
let g:netrw_banner = 0
" open files in previous window
let g:netrw_browse_split = 4
" Open netrw in a vertical split when opening vim
augroup ProjectDrawer
  autocmd!
  autocmd VimEnter * :Vexplore | wincmd p
augroup END
