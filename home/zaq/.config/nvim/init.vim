set nocompatible              " be iMproved, required
filetype off                  " required

call plug#begin('~/.local/share/nvim/plugged')

Plug 'ncm2/ncm2'
Plug 'roxma/nvim-yarp'

Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-tmux'
Plug 'ncm2/ncm2-path'

Plug 'ncm2/ncm2-jedi'
"Plug 'ncm2/ncm2-go'

Plug 'autozimu/LanguageClient-neovim', {
  \ 'branch': 'next',
  \ 'do': 'bash install.sh',
  \ }

Plug 'ncm2/ncm2-ultisnips'
Plug 'sirver/ultisnips'

Plug 'majutsushi/tagbar'
Plug 'mileszs/ack.vim'

Plug 'zaquestion/vim-monokai'
Plug 'tmhedberg/SimpylFold'

Plug 'tpope/vim-fugitive'
Plug 'shumphrey/fugitive-gitlab.vim'
Plug 'tpope/vim-rhubarb'

Plug 'scrooloose/syntastic'
Plug 'Chiel92/vim-autoformat'
Plug 'godlygeek/tabular'

" Graphviz Dot
Plug 'wannesm/wmgraphviz.vim'

" Time Tracking
Plug 'fatih/vim-go'

call plug#end()

set timeoutlen=1000 ttimeoutlen=10

" Some Linux distributions set filetype in /etc/vimrc.
" Clear filetype flags before changing runtimepath to force Vim to reload them.
if exists("g:did_load_filetypes")
	filetype off
	filetype plugin indent off
endif
set rtp+=/usr/local/go/misc/vim " replace $GOROOT with the output of: go env GOROOT
filetype plugin indent on
syntax on

if executable('ag')
	let g:ackprg = 'ag -Q --ignore-dir vendor --ignore-dir Vendors --ignore-dir app/ext/vendors'
endif
let g:ackhighlight = 1

" use Ag instead of Ack when typing
cnoreabbrev ag Ack
cnoreabbrev Ag Ack

"noremap <C-\> :exec 'Ack!' expand('<cword>') getcwd()<CR>
noremap <C-\> :exec 'Ack!' '"'.matchstr(getline("."), expand('<cword>').'(\?').'"' getcwd()<CR>

"remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

autocmd BufNewFile,BufRead *.diag set filetype=diag
autocmd BufNewFile,BufRead *.gv set filetype=dot

colorscheme monokai

set lazyredraw

" split preferences
set splitbelow
set splitright

set relativenumber
set number

" Remove awful omnicomplete scratch preview
set completeopt-=preview

" Shows matching ({[]})
set showmatch

" Allows case insensitive searching with smart exceptions
set ignorecase
set smartcase

" Path completion
set wildmode=longest,list
set wildmenu

" Do highlighting on search and macro do clear search
set hlsearch
nnoremap <leader><CR> :noh<CR>

" indentation
set shiftwidth=4
set expandtab

set pastetoggle=<F2>

" Keybinding hotkeys for switching windows
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

map + <C-w>+
map - <C-w>-

" Leader config
let mapleader=","
" starts a :e command in the same directory as the current buffer
nnoremap <leader>e :e <C-R>=expand("%:p:h") . "/" <CR>
nnoremap <leader>E :Explore<CR>
" re-executes the last command
nnoremap <leader><leader> @:
nnoremap <leader>ft :exec 'sp ~/.config/nvim/ftplugin/' . &filetype . '.vim' <CR>

set tags=$projects/tags
nmap <F8> :TagbarToggle<CR>

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<c-l>"
let g:UltiSnipsJumpForwardTrigger="<c-m>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"

let g:netrw_liststyle=3
let g:netrw_bufsettings = 'noma nomod nu nobl nowrap ro'

tnoremap <Esc> <C-\><C-n>
let g:terminal_scrollback_buffer_size = 2147483647

let g:formatters_python = ['yapf']
let g:formatdef_yapf = "'yapf --style=\"{based_on_style: pep8, indent_width: 4, join_multiple_lines: true, SPACE_BETWEEN_ENDING_COMMA_AND_CLOSING_BRACKET: false, COALESCE_BRACKETS: true, DEDENT_CLOSING_BRACKETS: true, COLUMN_LIMIT: 120}\" -l '.a:firstline.'-'.a:lastline"

let @s  = '^/self\.dwdwicfg["lguwwi"]'

let g:fugitive_gitlab_domains = ['https://gitlab.com']

" define a fancy nvim clipboard provider
let g:clipboard = {
  \   'name': 'Vim Clipboard',
  \   'copy': {
  \      '+': 'xclip -i -selection clipboard',
  \      '*': 'xclip -i -selection secondary',
  \    },
  \   'paste': {
  \      '+': 'xclip -o -selection clipboard',
  \      '*': 'xclip -o -selection secondary',
  \   },
  \   'cache_enabled': 1,
  \ }
" tell nvim to use * as its internal clipboard
" now vim sessions can share yank buffers by using the virtually unheard of
" secondary selection buffer!
set clipboard=unnamed

autocmd BufEnter  *  call ncm2#enable_for_buffer()
" Affects the visual representation of what happens after you hit <C-x><C-o>
" https://neovim.io/doc/user/insert.html#i_CTRL-X_CTRL-O
" https://neovim.io/doc/user/options.html#'completeopt'
"
" This will show the popup menu even if there's only one match (menuone),
" prevent automatic selection (noselect) and prevent automatic text injection
" into the current line (noinsert).
set completeopt=noinsert,menuone,noselect

" suppress the annoying 'match x of y', 'The only match' and 'Pattern not
" found' messages
set shortmess+=c

" CTRL-C doesn't trigger the InsertLeave autocmd . map to <ESC> instead.
inoremap <c-c> <ESC>

" When the <Enter> key is pressed while the popup menu is visible, it only
" hides the menu. Use this mapping to close the menu and also start a new
" line.
inoremap <expr> <CR> (pumvisible() ? "\<c-y>\<cr>" : "\<CR>")

" Use <TAB> to select the popup menu:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

let g:go_def_mapping_enabled = 0
nnoremap <c-]> :call LanguageClient#textDocument_definition()<CR>

" wrap existing omnifunc
" Note that omnifunc does not run in background and may probably block the
" editor. If you don't want to be blocked by omnifunc too often, you could
" add 180ms delay before the omni wrapper:
"  'on_complete': ['ncm2#on_complete#delay', 180,
"               \ 'ncm2#on_complete#omni', 'csscomplete#CompleteCSS'],
"au User Ncm2Plugin call ncm2#register_source({
"    \ 'name' : 'css',
"    \ 'priority': 9,
"    \ 'subscope_enable': 1,
"    \ 'scope': ['css','scss'],
"    \ 'mark': 'css',
"    \ 'word_pattern': '[\w\-]+',
"    \ 'complete_pattern': ':\s*',
"    \ 'on_complete': ['ncm2#on_complete#omni', 'csscomplete#CompleteCSS'],
"    \ })

" 'go': ['.git', 'go.mod'],
let g:LanguageClient_rootMarkers = {
        \ 'go': ['.git', 'go.mod'],
        \ }
let g:LanguageClient_loggingFile = '/tmp/lc.log'
let g:LanguageClient_loggingLevel = 'DEBUG'

" 'go': ['bingo', '-format-style', 'gofmt', '-disable-func-snippet'],
" 'go': ['bingo', '-format-style', 'gofmt', '-disable-func-snippet', '-enhance-signature-help'],
" 'go': ['tcp://127.0.0.1:4389'],
" 'go': ['forward', '-port=4389'],
let g:LanguageClient_serverCommands = {
    \ 'go': ['bingo', '-format-style', 'gofmt', '-disable-func-snippet', '-enhance-signature-help'],
    \ }
