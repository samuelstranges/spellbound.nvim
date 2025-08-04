-- Event handlers for spellbound mode keybindings

local ui = require("spellbound.ui")
local state = require("spellbound.state")
local config = require("spellbound.config")
local spell = require("spellbound.spell")

local on = {}

-- helper function
local function show_deferred_preview_on_selected_word()
	-- We use defer_fn to ensure the cursor has moved and the screen has updated
	vim.defer_fn(function()
		-- Then show the preview if still in spellcheck mode
		if state.enabled and config.ui.suggestion_preview then
			ui.show_suggestion_preview()
		end
	end, 1)
end

function on.on_next_word()
	spell.goto_next()
	show_deferred_preview_on_selected_word()
end

function on.on_prev_word()
	spell.goto_prev()
	show_deferred_preview_on_selected_word()
end

function on.on_auto_accept()
	local word = spell.get_current_word()
	local suggestion = spell.get_first_suggestion(word)

	-- Hide any existing suggestion preview
	ui.hide_suggestion_preview()

	-- Apply first suggestion if available
	if suggestion then
		-- Store the correction for potential "replace all" later
		state.last_correction = { word = word, correction = suggestion }

		-- Apply the correction
		spell.apply_correction(suggestion)
	else
		vim.api.nvim_echo({ { "No suggestions available", "WarningMsg" } }, false, {})
	end
end

function on.on_change_word()
	local word = spell.get_current_word()

	ui.hide_suggestion_preview()

	-- First use viw to select the word
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("viw", true, false, true), "n", false)

	-- Store current position and word for the TextChanged event
	state.current_word = {
		word = word,
		pos = vim.api.nvim_win_get_cursor(0),
	}

	-- Then send the c command to change the selection
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("c", true, false, true), "n", false)
end

function on.on_add_to_dict()
	ui.hide_suggestion_preview()
	spell.add_to_dictionary()
end

function on.on_ignore_word()
	ui.hide_suggestion_preview()
	spell.ignore_word()
end

function on.on_suggestions()
	ui.hide_suggestion_preview() -- Hide any existing suggestion preview
	ui.show_suggestions()
end

function on.on_undo()
	spell.undo()
end

function on.on_toggle_preview()
	ui.toggle_suggestion_preview()
end

return on
