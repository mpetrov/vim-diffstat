scriptencoding utf-8

if exists('g:loaded_diffstat')
  finish
endif

if !exists('g:diff_stat_git_command')
  let g:diff_stat_git_command = 'git'
endif

if !exists('g:diff_stat_path_simplifications')
  " These are useful for Guava, but probably not much else. Change them to suit
  " your needs if you have very long paths.
  let g:diff_stat_path_simplifications = {
        \ 'java/com/google': 'j/c/g',
        \ 'javatests/com/google': 'jt/c/g',
        \ 'third_party': 'tp'
        \ }
endif

command! -nargs=* -bar DiffStat call diffstat#run(<f-args>)

