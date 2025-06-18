-- spellbound.lua
-- Top level module loading for spellbound.nvim

-- Silently exit if Neovim doesn't have required functions
if not vim.fn.has("nvim-0.7") then
	return
end

-- Forward the require to the main module
vim.cmd([[
  augroup spellbound_reload_config
    autocmd!
    autocmd BufWritePost */spellbound/*.lua lua require('spellbound')
  augroup END
]])

