setlocal lazyredraw
let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }

nnoremap <leader>b :w<CR>:GoBuild<CR>
nnoremap <leader>t :w<CR>:GoTest<CR>
nnoremap <leader>r :GoReferrers<CR>
nnoremap <leader>p :GoChannelPeers<CR>
nnoremap <leader>m :GoImplements<CR>
nnoremap <leader>i :GoInfo<CR>
nnoremap <leader>d :GoDoc<CR>
