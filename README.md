# DiffStat

## Introduction

DiffStat is a plugin that runs `git diff --stat` in a new Vim window. It allows
for easy file navigation, by jumping to the file under the cursor when Enter is
pressed.

The standard command line returns paths relative to the git toplevel directory,
not the working directory.  It also simplifies paths, which breaks jumping by
file names. This plugin aims to correct those two problems, while displaying the
output in a syntax-highlighted 80-character window.

## Installation

It's recommended that you install the plugin using 
[Pathogen](https://github.com/tpope/vim-pathogen) or
[Vundle](https://github.com/gmarik/vundle). After the
plugin is installed update your help tags and see `:help DiffStat` for
instructions on how to use and configure the plugin.

## Usage

This plugin can be invoked using the `:DiffStat` command. When inside a repo,
run `:DiffStat [commits..]` to open the DiffStat window.

An example of this would be `:DiffStat HEAD~1` to view a diff against the
parent of the current tip.

See `:help DiffStat-usage` for more details.

## Mapping

One can easily remap `<leader>d`, for example, to view the last couple commit
points as follows:

`noremap <leader>d :DiffStat HEAD HEAD..HEAD~1 HEAD~1..HEAD~2<cr>`

## Screenshots 

![DiffStat Screenshot](https://raw.github.com/wiki/mpetrov/vim-diffstat/diffstat.png)

Using `:DiffStat HEAD HEAD~1` on the OpenJDK7 source.


