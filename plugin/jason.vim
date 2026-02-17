" plugin/jason.vim
" Jason - Polyglot Build Manager for Neovim
" Maintainer: Your Name
" License: MIT

" Prevent loading the plugin twice
if exists('g:loaded_jason')
  finish
endif
let g:loaded_jason = 1

" Save user's cpoptions
let s:save_cpo = &cpo
set cpo&vim

" Initialize the plugin
lua << EOF
-- Only load if Neovim
if vim.fn.has('nvim-0.8') == 0 then
  vim.api.nvim_err_writeln('Jason requires Neovim >= 0.8.0')
else
  -- Auto-setup with defaults if user hasn't configured
  if not _G.jason_setup_done then
    require('jason').setup()
    _G.jason_setup_done = true
  end
end
EOF

" Restore user's cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo
