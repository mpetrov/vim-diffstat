let g:diff_stat_git_command = 'git'

let s:diff_files_list = {}

function! g:DiffStatOpenFile()
  let name = s:DiffStatFileNameForLine('.')
  if strlen(name) 
  echo name .' ~~ ' . s:diff_files_list[name]
   execute "wincmd w"
   execute "edit " . s:diff_files_list[name]
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

function! s:DiffStatShortenPath(path, max_path_length)
  " Hardcode some googly patterns for now
  let path = substitute(a:path, 'java/com/google', 'j/c/g', '')
  let path = substitute(a:path, 'javatests/com/google', 'jt/c/g', '')

  let path = strlen(path) < a:max_path_length ? path : pathshorten(a:path)
  if a:max_path_length < strlen(path)
    return '...' . matchstr(path, '\v.{0,'. (a:max_path_length - 3) . '}$')
  endif
  return path
endfunction

function! s:DiffStatCommand(command)
  let max_path_length = 56
  let max_deltas_length = 16

  let toplevel = split(system(
        \ g:diff_stat_git_command . " rev-parse --show-toplevel"), "\n")[0]
  let command_result =
	\ system(g:diff_stat_git_command . " diff " . a:command . " --numstat")

  let files_list = {}
  let max_delta = 0
  let file_name_lengths = []

  for diff_line in split(command_result, "\n")
    let [inserts, deletes, name] =
	\ matchlist(diff_line, '\v\s*([0-9\-]+)\s+([0-9-]+)\s+(.+)')[1:3]
    let absolute_path =  toplevel . '/' . name
    let relative_path = fnamemodify(absolute_path, ':.')
    let display_path_name = s:DiffStatShortenPath(relative_path, max_path_length)
    let files_list[display_path_name] =
	\ {'inserts': inserts, 'deletes': deletes, 'name': relative_path}
    let max_delta = max([max_delta, inserts + deletes])
    let s:diff_files_list[display_path_name] = relative_path
    call add(file_name_lengths, strlen(display_path_name))
  endfor

  let max_deltas_length = min([max_delta, max_deltas_length])
  let longest_filename = max(file_name_lengths)
  unlet file_name_lengths

  for [key, value] in items(files_list)
    let deltas_string = ''
    if value['inserts'] ==# '-' || value['deletes'] ==# '-'
      let total = 'Bin'
    else
      let total = value['inserts'] + value['deletes']
      let inserts_count = max([value['inserts'] * max_deltas_length / max_delta,
	\ value['inserts'] + 0 > 0 ? 1 : 0])
      let deletes_count = max([value['deletes'] * max_deltas_length / max_delta,
	\ value['deletes'] + 0 > 0 ? 1 : 0])
      let deltas_string =
	\  ' ' . repeat('+',  inserts_count) . repeat('-',  deletes_count)
    endif

    let files_list[key]['string'] =
          \ printf('% -' . max_path_length . 's | % 4s%s',
          \ key, total, deltas_string)
  endfor
  return files_list
endfunction

function DiffStatCallSystem(commit)
  let text = "# git diff " . a:commit . "\n"
  let result = s:DiffStatCommand(a:commit)
  for [key, value] in items(result)
    let text = text . value['string'] . "\n"
  endfor
  return text . "\n"
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
  let s:diff_files_list = {}
  for commit in  a:000
    call append(line('$') - 1, split(DiffStatCallSystem(commit), '\v\n'))
  endfor
  setlocal readonly nomodifiable
  normal! gg
endfunction
command! -nargs=* -bar DiffStat call s:DiffStat(<f-args>)

