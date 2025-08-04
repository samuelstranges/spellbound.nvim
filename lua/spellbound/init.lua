-- Main entry point for the spellbound.nvim plugin

local M = {}
local state = require("spellbound.state")
local config = require("spellbound.config")
local ui = require("spellbound.ui")
local on = require("spellbound.on_functions")
local spell = require("spellbound.spell")

-- Key mappings configuration
local keys = {
	next_word = "w",
	prev_word = "b",
	auto_accept = "a",
	change_word = "c",
	add_to_dict = "d",
	ignore_word = "i",
	undo_change = "u",
	suggestions = "s",
	toggle_preview = "t",
	exit_spellbound = "<Esc>",
}

-- Remove keymaps when exiting spellcheck mode
local function remove_keymaps()
	for _, key_value in pairs(keys) do
		-- Use the 'key_value' as the keymap string to delete
		pcall(vim.keymap.del, "n", key_value, { buffer = 0 })
	end
end

-- Define keymaps for spellcheck mode
local function setup_keymaps()
	local default_opts = { buffer = 0, noremap = true, silent = true }

	vim.keymap.set("n", keys.next_word, on.on_next_word, default_opts)
	vim.keymap.set("n", keys.prev_word, on.on_prev_word, default_opts)
	vim.keymap.set("n", keys.auto_accept, on.on_auto_accept, default_opts)
	vim.keymap.set("n", keys.change_word, on.on_change_word, default_opts)
	vim.keymap.set("n", keys.add_to_dict, on.on_add_to_dict, default_opts)
	vim.keymap.set("n", keys.ignore_word, on.on_ignore_word, default_opts)
	vim.keymap.set("n", keys.undo_change, on.on_undo, default_opts)
	vim.keymap.set("n", keys.suggestions, on.on_suggestions, default_opts)
	vim.keymap.set("n", keys.toggle_preview, on.on_toggle_preview, default_opts)

	vim.keymap.set("n", keys.exit_spellbound, M.on_exit, default_opts)
end

-- Enter spellcheck mode
function M.enter_spellcheck_mode()
	if state.enabled then
		return
	end
	
	-- Ensure UI is initialized (only happens once)
	if not ui.is_initialized() then
		ui.setup(config.ui)
	end

	-- Enable spell checking
	spell.enable_spell()

	-- Ensure dictionary is loaded for faster operations
	spell.compile_spellfile()

	-- Save original timeout settings before modifying them
	state.original_timeoutlen = vim.api.nvim_get_option_value("timeoutlen", {})
	state.original_ttimeoutlen = vim.api.nvim_get_option_value("ttimeoutlen", {})

	-- Set very low timeout to make single-key mappings respond immediately
	vim.opt.timeoutlen = 50
	vim.opt.ttimeoutlen = 0

	-- Set up keymaps
	setup_keymaps()

	-- Show UI helper if enabled
	if ui.should_show_ui() then
		ui.show_spellcheck_ui(keys)
	end

	-- Show suggestion preview if we start on a misspelled word
	if config.ui.suggestion_preview then
		local word = spell.get_current_word()
		if spell.is_misspelled(word) then
			ui.show_suggestion_preview()
		end
	end

	state.enabled = true
end

-- Setup function
function M.setup(opts)
	opts = opts or {}

	if opts.mappings and opts.mappings.leader then
		config.mappings.leader = opts.mappings.leader
	end

	if opts.ui then
		if type(opts.ui.enable) == "boolean" then
			config.ui.enable = opts.ui.enable
		end
		if type(opts.ui.suggestion_preview) == "boolean" then
			config.ui.suggestion_preview = opts.ui.suggestion_preview
		end
	end

	-- Define mapping to enter spellcheck mode (lazy-loaded)
	local keymap_opts = { noremap = true, silent = true, desc = "Enter spellbound mode" }

	vim.keymap.set("n", config.mappings.leader, function()
		-- This ensures the module is only loaded when actually used
		require('spellbound').enter_spellcheck_mode()
	end, keymap_opts)

	-- Don't initialize UI until it's actually needed
	-- ui.setup will be called when entering spellcheck mode
end

function M.on_exit()
	if not state.enabled then
		return
	end

	remove_keymaps()
	ui.hide_spellcheck_ui()
	ui.hide_suggestion_preview()

	-- Restore original timeout settings
	if state.original_timeoutlen then
		vim.opt.timeoutlen = state.original_timeoutlen
	end
	if state.original_ttimeoutlen then
		vim.opt.ttimeoutlen = state.original_ttimeoutlen
	end

	state.enabled = false
end

return M
