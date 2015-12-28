command! Firefox call OpenInFireFox()

function! OpenInFireFox()
	let path=expand("%:p")
	let file=expand("%:t")
	let svgname=split(l:file, '\.')[0].".svg"
  	execute 'silent! !firefox '.l:svgname
	redraw!
endfunction

function! RenderDotSvg()
	let path=expand("%:p")
	let pathhead=expand("%:p:h")
	let file=expand("%:t")
	let svgname=split(l:file, '\.')[0].".svg"
  	execute "silent! !dot -Tsvg ".l:path." > ".l:pathhead."/".l:svgname
	redraw!
endfunction
autocmd BufWritePost * :call RenderDotSvg()
