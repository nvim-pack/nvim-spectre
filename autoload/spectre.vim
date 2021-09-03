function! spectre#foldexpr() abort
    if get(b:, "spectre_fold" , 0) == 1
      return 0
    endif
    return luaeval(printf('require"spectre".get_fold(%d)', v:lnum))
endfunction
