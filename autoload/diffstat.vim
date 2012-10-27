scriptencoding utf-8

if !exists(':DiffStat') == 0
  runtime plugin/diffstat.vim
endif

if exists('g:loaded_diffstat')
  finish
endif


" Maps visible file names to actual system paths.
let s:diff_files_list = {}

function! g:DiffStatOpenFile()
  let l:name = s:DiffStatFileNameForLine('.')
  if strlen(l:name)
    execute "wincmd w"
    execute "edit " . s:diff_files_list[l:name]
  end
endfunction

" Displays the DiffStat window if show is true, otherwise hide it.
function! s:DisplayWindow(show)
  let l:nr = bufwinnr("__diffstat__")
  if !a:show
    if l:nr >= 0
      execute l:nr . " wincmd w"
      execute "wincmd c"
    endif
    return
  endif

  if l:nr < 0
    split __diffstat__
  else
    execute l:nr . " wincmd w"
  endif
  setlocal noreadonly modifiable
  normal! gg"_dGA
  setlocal filetype=diffstat
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal foldcolumn=0
  setlocal nobuflisted
  setlocal nofoldenable
  setlocal nolist
  setlocal nonumber
  setlocal nospell
  setlocal noswapfile
  setlocal nowrap
  setlocal statusline=DiffStat
  setlocal textwidth=0
  setlocal winfixwidth
  if exists('+colorcolumn')
    setlocal colorcolumn=
  endif
  if exists('+relativenumber')
    setlocal norelativenumber
  endif

  setlocal foldmethod=expr
  setlocal foldexpr=s:DiffStatFold(v:lnum)

  nnoremap  <script> <buffer> <silent> <cr> :call g:DiffStatOpenFile()<cr>

endfunction

function! s:DiffStatShortenPath(path, max_path_length)
  let l:path = a:path
  for [l:pattern, l:replacement] in items(g:diff_stat_path_simplifications)
    let l:path = substitute(l:path, l:pattern, l:replacement, '')
  endfor
  let l:path = strlen(l:path) < a:max_path_length ? l:path : pathshorten(l:path)
  if a:max_path_length < strlen(l:path)
    return '...' . matchstr(l:path, '\v.{0,'. (a:max_path_length - 3) . '}$')
  endif
  return l:path
endfunction

function! s:DiffStatCommand(command)
  let max_path_length = 56

  let l:command_result =
        \ system(g:diff_stat_git_command . " diff " . a:command . " --numstat")

  let files_list = {}
  let l:max_deltas = 0
  for diff_line in split(l:command_result, "\n")
    let [inserts, deletes, name] =
          \ matchlist(diff_line, '\v\s*([0-9\-]+)\s+([0-9-]+)\s+(.+)')[1:3]
    if inserts !=# '0' || deletes !=# '0'
      let absolute_path =  s:toplevel . '/' . name
      let relative_path = fnamemodify(absolute_path, ':.')
      let display_path_name = s:DiffStatShortenPath(relative_path, max_path_length)
      let files_list[display_path_name] =
            \ {'inserts': inserts, 'deletes': deletes, 'name': relative_path}
      let l:max_deltas = max([l:max_deltas, inserts + deletes])
      let s:diff_files_list[display_path_name] = relative_path
    endif
  endfor

  let l:max_deltas_string_length = min([l:max_deltas, 16])

  for [key, value] in items(files_list)
    let deltas_string = ''
    let total = 'Bin'
    if value['inserts'] !=# '-' && value['deletes'] !=# '-'
      let total = value['inserts'] + value['deletes']
      let inserts_count = max([
            \ value['inserts'] * l:max_deltas_string_length / l:max_deltas,
            \ value['inserts'] + 0 > 0 ? 1 : 0])
      let deletes_count = max([
            \ value['deletes'] * l:max_deltas_string_length / l:max_deltas,
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

function! s:GetTotalsString(files_list)
  let l:inserts_total = 0
  let l:deletes_total = 0
  for [key, value] in items(a:files_list)
    if value['inserts'] !=# '-' && value['deletes'] !=# '-'
      let l:inserts_total += value['inserts']
      let l:deletes_total += value['deletes']
    endif
  endfor
  return printf("%d files changed, %d insertions(+), %d deletions",
    \ len(a:files_list), l:inserts_total, l:deletes_total)
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

function! diffstat#run(...)
  let s:toplevel = split(system(
        \ g:diff_stat_git_command . " rev-parse --show-toplevel"), "\n")[0]
  if s:toplevel =~# '\v^\s*$' || !isdirectory(s:toplevel)
    call s:DisplayWindow(0)
    echohl WarningMsg
    echomsg "DiffStat can only be run in a .git repo"
    echohl None
    return
  endif
  call s:DisplayWindow(1)
  let s:diff_files_list = {}
  let l:commits = a:000
  if empty(l:commits)
    let l:commits = ['HEAD']
  end
  let l:lines = []
  for l:commit in l:commits
    if !empty(l:lines)
      call add(l:lines, "")
    endif
    call add(l:lines, "#" . g:diff_stat_git_command . " diff " . l:commit)
    let l:files_list = s:DiffStatCommand(l:commit)
    for [key, value] in items(l:files_list)
      call add(l:lines, value['string'])
    endfor
    call add(l:lines, s:GetTotalsString(l:files_list))
  endfor
  call append(0, l:lines)
  normal! G"_ddgg
  call setpos(1, 1)
  setlocal readonly nomodifiable
  setlocal statusline="DiffStat " . join(a:000, ' ')
endfunction

