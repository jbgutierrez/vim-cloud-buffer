" =============================================================================
" File:          plugin/cloud_buffer.vim
" Author:        Javier Blanco <http://jbgutierrez.info>
" =============================================================================

if ( exists('g:loaded_cloud_buffer') && g:loaded_cloud_buffer ) || v:version < 700 || &cp
  finish
endif
" let g:loaded_cloud_buffer = 1

if !has('ruby')
  echohl WarningMsg
  echo "vim-cloud-buffer requires Vim to be compiled with Ruby support"
  echohl none
  finish
endif

unlet! g:vim_cloud_buffer_data
let g:vim_cloud_buffer_data=0

" Functions {{{

function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction

function! s:debug(str)
  if exists("g:cloud_buffer_debug") && g:cloud_buffer_debug
    echohl Debug
    echomsg a:str
    echohl None
  endif
endfunction

function! s:sub(str,pat,rep)
  return substitute(a:str,'\v\C'.a:pat,a:rep,'')
endfunction

ruby load "./ruby/cloud_buffer.rb"

let s:bufprefix = 'buffers' . (has('unix') ? ':' : '_')

function! s:buffer_add() abort
  redraw | echon 'Saving buffer... '
  let content = join(getline(0, line('$')), "\n")

  unlet! g:vim_cloud_buffer_data
  let g:vim_cloud_buffer_data = { "content": content }
  ruby VimCloudBuffer::Client.new.add()
  let buffer = g:vim_cloud_buffer_data

  let old_undolevels = &undolevels

  close
  let buffer_name = s:bufprefix.'edit:'.b:buffer_id
  exec 'silent noautocmd split' buffer_name

  set ft=markdown

  let content = buffer.content
  call setline(1, split(content, "\n"))
  let b:buffer = buffer
  let b:buffer_id = buffer._id['$oid']

  let &undolevels = old_undolevels

  setlocal buftype=acwrite noswapfile
  setlocal nomodified

  au! BufWriteCmd <buffer> call s:buffer_update()

  redraw | echo ''
endfunction

function! s:buffer_update() abort
  redraw | echon 'Updating buffer... '
  let content = join(getline(0, line('$')), "\n")
  let b:buffer.content = content

  unlet! g:vim_cloud_buffer_data
  let g:vim_cloud_buffer_data = b:buffer
  exe "ruby VimCloudBuffer::Client.new.update('".b:buffer_id."')"
  let buffer = g:vim_cloud_buffer_data

  redraw | echo ''
endfunction

function! s:buffer_get(id) abort
  redraw | echon 'Getting buffer... '

  exe "ruby VimCloudBuffer::Client.new.get('".a:id."')"
  let buffer = g:vim_cloud_buffer_data

  let old_undolevels = &undolevels

  close
  let buffer_name = s:bufprefix.'edit:'.a:id
  exec 'silent noautocmd split' buffer_name

  set ft=markdown

  let content = buffer.content
  call setline(1, split(content, "\n"))
  let b:buffer = buffer
  let b:buffer_id = buffer._id['$oid']

  let &undolevels = old_undolevels
  setlocal buftype=acwrite noswapfile
  setlocal nomodified

  au! BufWriteCmd <buffer> call s:buffer_update()

  redraw | echo ''
endfunction

function! s:format_buffer(buffer) abort
  let g:buffer = a:buffer
  let content = substitute(a:buffer.content, '[\r\n\t]', ' ', 'g')
  let content = substitute(content, '  ', ' ', 'g')
  return printf('buffer: %s %s', a:buffer._id['$oid'], content)
endfunction

function! s:buffers_list_action() abort
  let line = getline('.')
  let regex = '^buffer: \([0-9a-z]\+\) '
  if line =~ regex
    let id = matchlist(line, regex)[1]
    call s:buffer_get(id)
  endif
endfunction

function! s:buffers_list() abort
  redraw | echon 'Listing buffers... '

  let buffer_name = s:bufprefix.'list'
  let winnum = bufwinnr(bufnr(buffer_name))
  if winnum != -1
    if winnum != bufwinnr('%')
      exe winnum 'wincmd w'
    endif
  else
    exec 'silent noautocmd split' buffer_name
  endif

  ruby VimCloudBuffer::Client.new.list
  let buffers = g:vim_cloud_buffer_data

  setlocal modifiable
  let lines = map(buffers, 's:format_buffer(v:val)')
  call setline(1, split(join(lines, "\n"), "\n"))
  setlocal nomodifiable
  setlocal buftype=nofile bufhidden=hide noswapfile

  nnoremap <silent> <buffer> <cr> :call <SID>buffers_list_action()<cr>

  redraw | echo ''
endfunction

function! s:CloudBuffer(bang) abort
  if exists('b:buffer')
    call s:buffer_update()
  elseif a:bang
    call s:buffer_add()
  else
    call s:buffers_list()
  endif
endfunction

"}}}

" Commands {{{

command! -bang CloudBuffer call <sid>CloudBuffer(<bang>0)

"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
