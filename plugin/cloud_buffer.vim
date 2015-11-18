" =============================================================================
" File:          plugin/cloud_buffer.vim
" Author:        Javier Blanco <http://jbgutierrez.info>
" =============================================================================

if ( exists('g:loaded_cloud_buffer') && g:loaded_cloud_buffer ) || v:version < 700 || &cp
  finish
endif

if !has('ruby')
  echohl WarningMsg
  echo "vim-cloud-buffer requires Vim to be compiled with Ruby support"
  echohl none
  finish
endif

command! -nargs=? -bang -complete=customlist,cloud_buffer#CloudBufferArgs CloudBuffer call cloud_buffer#CloudBuffer(<bang>0, <f-args>)

" vim:fen:fdm=marker:fmr=function,endfunction:fdl=0:fdc=1:ts=2:sw=2:sts=2
