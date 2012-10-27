if exists("b:diffstat_syntax")
  "finish
endif

syntax match diffStatBranch "\v\S+$"
highlight link diffStatBranch Keyword

syn region diffStatComment start="\v^#" end="\n" contains=diffStatBranch
highlight link diffStatComment Comment

syntax keyword diffStatBin Bin
highlight link diffStatBin Comment

syntax match diffStatSeparator "\v\|"
highlight link diffStatSeparator Comment

highlight DiffStatAdd ctermfg=green
highlight DiffStatRemove ctermfg=red

syntax match diffStatRemove "\v\-+"
highlight link diffStatRemove DiffStatRemove
syntax match diffStatAdd "\v\++"
highlight link diffStatAdd DiffStatAdd

syn region diffStatLine start="|" end="\n"
      \ contains=diffStatAdd,diffStatRemove,diffStatSeparator,diffStatBin

syn region diffStatFile start="\v^[^#]" end="|\@=" skip=/\\|/
highlight link diffStatFile Normal



let b:diffstat_syntax = "diffstat"
