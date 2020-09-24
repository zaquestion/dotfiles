setlocal lazyredraw
let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }

nnoremap <leader>b :GoBuild<CR>
nnoremap <leader>t :GoTest -tags="unit"<CR>
nnoremap <leader><leader>t :GoTestFunc -tags="unit"<CR>
nnoremap <leader>r :GoReferrers<CR>
nnoremap <leader>p :GoChannelPeers<CR>
nnoremap <leader>m :GoImplements<CR>
nnoremap <leader>i :GoInfo<CR>
nnoremap <leader>d :GoDoc<CR>

set shiftwidth=8
