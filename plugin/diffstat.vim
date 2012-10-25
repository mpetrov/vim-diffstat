let g:DiffStatGitCommand = 'git'

function! g:DiffStatOpenFile()
  let name = s:DiffStatFileNameForLine('.')
  if strlen(name) 

   execute "wincmd w"
   execute "edit " . name
  end
endfunction

function! s:DisplayBuffer()
  let nr = bufwinnr("__diffstat__")
  if nr < 0
    split __diffstat__
  else
   execute nr . " wincmd w"
  endif
  setlocal noreadonly modifiable
  normal! ggdGA
  setlocal filetype=diffstat
  setlocal buftype=nofile noswapfile bufhidden=hide nobuflisted 
  setlocal foldmethod=expr
  setlocal foldexpr=s:DiffStatFold(v:lnum)
  nnoremap  <script> <buffer> <silent> <cr> :call g:DiffStatOpenFile()<cr>
endfunction

function DiffStatCallSystem(commit)
  " TODO(mpetrov): consider using diff-tree or --numstat
  let command = g:DiffStatGitCommand . " diff " . a:commit 
  let text = system(command . " --stat=140,100,100")
  let heading = "# " . command . "\n"
  return heading . text . "\n"
endfunction

let s:DiffStatRegex = '\v^\s*(\S+)\s*\|\s*\d+\s*[+-]+\s*$'
function! s:DiffStatFileNameForLine(lnum) 
   if getline(a:lnum) =~? s:DiffStatRegex
     return matchlist(getline(a:lnum), s:DiffStatRegex)[1]
   endif
   return ''
endfunction

function! s:DiffStatFold(lnum)
  if getline(a:lnum) =~? '\v^\s*$'
    return '0'
  elseif getline(a:lnum) =~? '\v^#$'
    return '1>'
  else
    return '1'
  endif
endfunction

function! s:DiffStat(...)
  call s:DisplayBuffer()
  for commit in  a:000
    call append(line('$') - 1, split(DiffStatCallSystem(commit), '\v\n'))
  endfor
  setlocal readonly nomodifiable
  normal! gg
endfunction
command! -nargs=* -bar DiffStat call s:DiffStat(<f-args>)

