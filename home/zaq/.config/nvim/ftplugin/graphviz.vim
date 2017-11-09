function! RenderDotPNG()
	let path=expand("%:p")
	let pathhead=expand("%:p:h")
	let file=expand("%:t")
	let pngname=split(l:file, '\.')[0].".png"
  	execute "silent! !dot -Tpng ".l:path." > ".l:pathhead."/".l:pngname
	execute 'silent! !pkill -9 feh'
  	call jobstart(["feh", l:pngname])
endfunction
autocmd BufWritePost *.gv :call RenderDotPNG()
