-- spellbound.lua
-- Plugin initialization for spellbound.nvim (lazy-loaded)

-- Require Neovim 0.7 or later
if vim.fn.has("nvim-0.7") ~= 1 then
	return
end

-- Create user command for lazy loading
vim.api.nvim_create_user_command("Spellbound", function()
	require("spellbound").enter_spellcheck_mode()
end, { desc = "Enter spellbound mode" })

-- Note: The actual keymap is set up by the user via setup()
-- or they can use the command directly