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

let s:bufprefix = 'buffers' . (has('unix') ? ':' : '_')
function! s:buffer_open(buffer_name, split) abort
  let buffer_name = s:bufprefix.a:buffer_name
  let winnum = bufwinnr(bufnr(buffer_name))
  if winnum != -1
    if winnum != bufwinnr('%')
      exe winnum 'wincmd w'
    endif
  else
    if (a:split)
      exe 'split' buffer_name
    endif
  endif
endfunction

exe "rubyfile " . expand('<sfile>:p:h') . "/../ruby/cloud_buffer.rb"

function! s:buffer_add() abort
  let content = join(getline(0, line('$')), "\n")

  unlet! g:vim_cloud_buffer_data
  let g:vim_cloud_buffer_data = { "content": content }
  redraw | echomsg 'Saving buffer... '
  ruby VimCloudBuffer::gw.add()
  let buffer = g:vim_cloud_buffer_data

  let content = buffer.content
  call setline(1, split(content, "\n"))
  setlocal nomodified
  let b:buffer = buffer
  let b:buffer_id = buffer._id['$oid']

  au! BufWriteCmd <buffer> call s:buffer_update()

  redraw | echo ''
endfunction

function! s:buffer_update() abort

  let b:buffer.content = join(getline(0, line('$')), "\n")
  unlet! g:vim_cloud_buffer_data
  let g:vim_cloud_buffer_data = b:buffer
  redraw | echomsg 'Updating buffer... '
  exe "ruby VimCloudBuffer::gw.update('".b:buffer_id."')"
  let buffer = g:vim_cloud_buffer_data
  setlocal nomodified

  redraw | echo ''
endfunction

function! s:buffer_get(id) abort
  call s:buffer_open('edit:'.a:id, 0)
  if (exists('b:buffer')) | return | endif

  redraw | echomsg 'Getting buffer... '
  exe "ruby VimCloudBuffer::gw.get('".a:id."')"
  let buffer = g:vim_cloud_buffer_data
  call s:buffer_open('edit:'.a:id, 1)

  call setline(1, split(buffer.content, "\n"))
  let b:buffer = buffer
  let b:buffer_id = buffer._id['$oid']
  au! BufWriteCmd <buffer> call s:buffer_update()
  setlocal buftype=acwrite bufhidden=delete noswapfile
  setlocal nomodified

  redraw | echo ''
endfunction

function! s:format_buffer(buffer) abort
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
  redraw | echomsg 'Listing buffers... '
  ruby VimCloudBuffer::gw.list
  let buffers = g:vim_cloud_buffer_data
  call s:buffer_open('list', 1)

  setlocal modifiable
  let lines = map(buffers, 's:format_buffer(v:val)')
  0,%delete
  call setline(1, split(join(lines, "\n"), "\n"))
  setlocal nomodifiable
  setlocal buftype=nofile bufhidden=delete noswapfile

  nnoremap <silent> <buffer> <cr> :call <sid>buffers_list_action()<cr>

  redraw | echo ''
endfunction

function! s:buffer_delete() abort
  redraw | echomsg 'Deleting buffer... '
  exe "ruby VimCloudBuffer::gw.remove('".b:buffer_id."')"

  redraw | echo ''
endfunction

function! s:CloudBuffer(bang, ...) abort
  let args = (a:0 > 0) ? split(a:1, '\W\+') : [ 'list' ]
  for arg in args
    if arg =~# '\v^(l|list)$'
      call s:buffers_list()
    elseif arg =~# '\v^(d|delete)$'
      call s:buffer_delete()
    elseif arg =~# '\v^(s|save)$'
      if exists('b:buffer')
        call s:buffer_update()
      else
        call s:buffer_add()
      end
    end
  endfor
endfunction

"}}}

" Commands {{{

function! s:CloudBufferArgs(A,L,P)
  return [ "-l", "--list", "-d", "--delete", "-s", "--save" ]
endfunction

command! -nargs=? -bang -complete=customlist,<sid>CloudBufferArgs CloudBuffer call <sid>CloudBuffer(<bang>0, <f-args>)

"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
