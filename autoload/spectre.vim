function! spectre#foldexpr() abort
    return luaeval(printf('_G.__spectre_fold(%d)', v:lnum))
endfunction
