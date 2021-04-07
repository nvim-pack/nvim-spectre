function! spectre#foldexpr() abort
	return luaeval(printf('require"spectre".get_fold(%d)', v:lnum))
endfunction
