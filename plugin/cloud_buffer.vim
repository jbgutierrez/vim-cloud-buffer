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
function! s:rest_api(cmd, ...)
  if (a:0 > 0)
    unlet! g:vim_cloud_buffer_data
    let g:vim_cloud_buffer_data = a:1
  endif
  exe "ruby VimCloudBuffer::gw.".a:cmd
  return g:vim_cloud_buffer_data
endfunction

function! s:serialize_buffer()
  let buffer = {}
  let pos = getpos('.')
  let options = {
    \ 'filetype': &filetype,
    \ 'lnum': pos[1],
    \ 'col': pos[2]
    \ }
  call extend(buffer, {
    \ 'content': join(getline(0, line('$')), "\n"),
    \ 'options': options,
    \ 'updated_at': localtime()
    \ })
  return buffer
endfunction

function! s:buffer_add() abort
  redraw | echomsg 'Saving buffer... '

  let buffer = s:serialize_buffer()
  let buffer.created_at = localtime()
  let buffer = s:rest_api('add', buffer)

  let content = buffer.content
  call setline(1, split(content, "\n"))
  setlocal nomodified
  let b:buffer = buffer
  let b:buffer_id = buffer._id['$oid']

  au! BufWriteCmd <buffer> call s:buffer_update()

  redraw | echo ''
endfunction

function! s:buffer_update() abort
  redraw | echomsg 'Updating buffer... '
  let buffer = s:rest_api('update("'.b:buffer_id.'")', s:serialize_buffer())
  setlocal nomodified
  redraw | echo ''
endfunction

function! s:buffer_get(id) abort
  call s:buffer_open('edit:'.a:id, 0)
  if (exists('b:buffer')) | return | endif

  redraw | echomsg 'Getting buffer... '
  let buffer = s:rest_api('get("'.a:id.'")')
  call s:buffer_open('edit:'.a:id, 1)
  call setline(1, split(buffer.content, "\n"))
  let options = buffer.options
  let &filetype = options.filetype
  call cursor(options.lnum, options.col)
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
  let id      = a:buffer._id['$oid']
  if exists('a:buffer.deleted_at') | exe 'syn match CloudBufferDeleted ".*'.id.'.*"' | endif
  return printf('buffer: %s %s', id, content)
endfunction

function! s:buffers_list_action(action) abort
  let line = getline('.')
  let regex = '^buffer: \([0-9a-z]\+\) '
  if line =~ regex
    let id = matchlist(line, regex)[1]
    if a:action == 'get'
      call s:buffer_get(id)
    elseif a:action == 'restore'
      call s:buffer_restore(id)
    end
  endif
endfunction

function! s:buffers_list(include_deleted) abort
  redraw | echomsg 'Listing buffers... '

  let options = {
        \   's': {
        \     'updated_at': -1
        \   },
        \   'q': {
        \     'deleted_at': { '$exists': 0 }
        \   }
        \ }
  if a:include_deleted | unlet options.q | endif
  let buffers = s:rest_api('list', options)
  call s:buffer_open('list', 1)

  hi def link CloudBufferDeleted Comment
  syn clear CloudBufferDeleted
  setlocal modifiable
  let lines = map(buffers, 's:format_buffer(v:val)')
  0,%delete
  call setline(1, split(join(lines, "\n"), "\n"))
  setlocal nomodifiable
  setlocal buftype=nofile bufhidden=delete noswapfile

  nnoremap <silent> <buffer> <cr> :call <sid>buffers_list_action('get')<cr>
  nnoremap <silent> <buffer> r :call <sid>buffers_list_action('restore')<cr>

  redraw | echo ''
endfunction

function! s:buffer_delete(permanent) abort
  let choice = confirm("Are you sure you want to delete?", "&Yes\n&No", 0)
  if choice != 1 | return | endif
  redraw | echomsg 'Deleting buffer... '
  if a:permanent
    call s:rest_api('remove("'.b:buffer_id.'")')
  else
    let b:buffer.deleted_at = localtime()
    call s:rest_api('update("'.b:buffer_id.'")', b:buffer)
  end
  redraw | echo ''
endfunction

function! s:buffer_restore(id) abort
  redraw | echomsg 'Restoring deleted buffer... '
  call s:rest_api('update("'.a:id.'")', { '$unset': { 'deleted_at': 1 } })
  redraw | echo ''
endfunction

function! s:CloudBuffer(bang, ...) abort
  let args = (a:0 > 0) ? split(a:1, '\W\+') : [ 'list' ]
  for arg in args
    try
      if arg =~# '\v^(l|list)$'
        call s:buffers_list(a:bang)
      elseif arg =~# '\v^(d|delete)$'
        call s:buffer_delete(a:bang)
      elseif arg =~# '\v^(s|save)$'
        if exists('b:buffer')
          call s:buffer_update()
        else
          call s:buffer_add()
        end
      end
    catch
      call s:error(v:errmsg)
    endtry
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
