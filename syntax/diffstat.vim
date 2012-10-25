if exists("b:diffstat_syntax")
  finish
endif

syntax match diffstatComment "\v(#.*$)|(\|)"
highlight link diffstatComment Comment

highlight DiffStatAdd ctermfg=green
highlight DiffStatRemove ctermfg=red

syntax match diffStatRemove "\v\-+"
highlight link diffStatRemove DiffStatRemove
syntax match diffStatAdd "\v\++"
highlight link diffStatAdd DiffStatAdd

let b:diffstat_syntax = "diffstat"
