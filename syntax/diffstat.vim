scriptencoding utf-8
if exists('b:diffstat_syntax')
  finish
endif

syntax match diffStatBranch '\v\S+$'
highlight default link diffStatBranch Keyword

syntax keyword diffStatBin Bin
highlight default link diffStatBin Comment

highlight default DiffStatAddHl ctermfg=green
highlight default DiffStatRemoveHl ctermfg=red

syntax match diffStatRemove '\v\-+'
highlight default link diffStatRemove DiffStatRemoveHl
syntax match diffStatAdd '\v\++'
highlight default link diffStatAdd DiffStatAddHl
syntax match diffStatSeparator '\v\|'
highlight default link diffStatSeparator Comment

syn region diffStatLine start='|' end='\n'
  \ contains=diffStatAdd,diffStatRemove,diffStatSeparator,diffStatBin

syn region diffStatFile start='\v^[^#]' end='|\@=' skip=/\\|/
highlight default link diffStatFile Normal

syn region diffStatComment start='\v^#' end='\n' contains=diffStatBranch
highlight default link diffStatComment Comment

syntax match diffStatTotals '\v^.*file.*change.*insertion.*deletion.*$'
highlight default link diffStatTotals Comment

let b:diffstat_syntax = 'diffstat'
