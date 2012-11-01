scriptencoding utf-8

if !exists(':DiffStat') == 0
  runtime plugin/diffstat.vim
endif

if exists('g:loaded_diffstat')
  finish
endif

let s:GIT_ERROR = "GIT ERROR"

" Maps visible file names to actual system paths.
let s:diff_files_list = {}
let s:diff_commits_list = {}

function! s:DiffStatOpenFile(fugitive_command)
  let l:file_name = get(s:diff_files_list, line('.'), '')
  let l:commit = get(s:diff_commits_list, line('.'), '')
  if strlen(l:file_name)
    if strlen(a:fugitive_command)
      if exists(':' . a:fugitive_command) < 1
          echohl ErrorMsg
          echomsg "Couldn't find :" . a:fugitive_command . 
                \ " command. This requires fugitive, make sure it's installed!"
          echohl None
          return 0
      endif
      call system(g:diff_stat_git_command .
            \ " rev-parse " . l:commit .":" . l:file_name)
      if v:shell_error
        echohl ErrorMsg
        echomsg l:file_name . " does not exist in " . l:commit
        echohl None
        return 0
      endif
    endif
    execute "wincmd w"
    execute "edit " . l:file_name
    if strlen(a:fugitive_command)
      silent execute  a:fugitive_command . " " . l:commit . ":" . l:file_name
    endif
  endif
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
    setlocal filetype=diffstat
    setlocal bufhidden=delete
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
  else
    execute l:nr . " wincmd w"
  endif

  setlocal noreadonly modifiable
  normal! gg"_dGA

  setlocal foldmethod=expr
  setlocal foldexpr=s:DiffStatFold(v:lnum)

  if !hasmapto("DiffStatOpenFile", "\n")
    nnoremap  <script> <buffer> <silent> <cr> :call <SID>DiffStatOpenFile('')<cr>
    nnoremap  <script> <buffer> <silent> D :call <SID>DiffStatOpenFile('Gdiff')<cr>
    nnoremap  <script> <buffer> <silent> dd :call <SID>DiffStatOpenFile('Gdiff')<cr>
    nnoremap  <script> <buffer> <silent> dh :call <SID>DiffStatOpenFile('Gsdiff')<cr>
    nnoremap  <script> <buffer> <silent> ds :call <SID>DiffStatOpenFile('Gsdiff')<cr>
    nnoremap  <script> <buffer> <silent> dv :call <SID>DiffStatOpenFile('Gvdiff')<cr>
    nnoremap  <script> <buffer> <silent> e :call <SID>DiffStatOpenFile('Gedit')<cr>
    nnoremap  <script> <buffer> <silent> gf :call <SID>DiffStatOpenFile('')<cr>
  endif

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
  if v:shell_error
    throw s:GIT_ERROR
  endif

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
  return printf("%s changed, %s(+), %s(-)",
    \ s:FormatCountString('file', len(a:files_list)),
    \ s:FormatCountString('insertion', l:inserts_total),
    \ s:FormatCountString('deletion', l:deletes_total))
endfunction

function! s:FormatCountString(str, count)
  return a:count . " " . a:str . (a:count == 1 ? "" : "s")
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
  if v:shell_error 
    call s:DisplayWindow(0)
    echohl ErrorMsg
    echomsg "DiffStat can only be run in a .git repo"
    echohl None
    return 0
  endif
  call s:DisplayWindow(1)
  let s:diff_files_list = {}
  let s:diff_commits_list = {}
  let l:commits = a:000
  if empty(l:commits)
    let l:commits = ['HEAD']
  end
  let l:lines = []
  for l:commit in l:commits
    if !empty(l:lines)
      call add(l:lines, "")
    endif
    call add(l:lines, "# " . g:diff_stat_git_command . " diff " . l:commit)
    try 
      let l:files_list = s:DiffStatCommand(l:commit)
    catch 
      call s:DisplayWindow(0)
      echohl ErrorMsg
      echomsg "Unknown revision or path " . l:commit . " in working tree."
      echohl None
      return 0
    endtry
    for [key, value] in items(l:files_list)
      call add(l:lines, value['string'])
      let s:diff_files_list[len(l:lines)] = value['name']
      let s:diff_commits_list[len(l:lines)] = l:commit
    endfor
    call add(l:lines, s:GetTotalsString(l:files_list))
  endfor
  call append(0, l:lines)
  normal! G"_ddgg
  call setpos(1, 1)
  setlocal readonly nomodifiable
  setlocal statusline="DiffStat " . join(a:000, ' ')
  return 1
endfunction

let g:loaded_diffstat = 1
