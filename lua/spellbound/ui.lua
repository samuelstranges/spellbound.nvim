-- UI components for the spellcheck mode

local M = {}
local spell = require("spellbound.spell")

-- UI state tracking
local state = {
	preview_enabled = true, -- Track if preview is enabled by user toggle
	ui_winid = nil,
	ui_bufnr = nil,
	suggest_winid = nil,
	suggest_bufnr = nil,
	orig_win = nil,
	preview_extmark_id = nil,
	preview_namespace = nil,
	preview_winid = nil, -- Floating window for suggestion preview
	preview_bufnr = nil, -- Buffer for suggestion preview
	color_namespace = vim.api.nvim_create_namespace("spellbound_color"),
}

-- Create help UI content
local function create_help_content(keys)
	local lines = {
		"                 *-~*~* spellbound *~*~-*                 ",
		"  ",
		" "
			.. keys.next_word
			.. " - next word       "
			.. keys.prev_word
			.. " - prev word       "
			.. keys.auto_accept
			.. " - auto fix",
		" "
			.. keys.change_word
			.. " - change word     "
			.. keys.add_to_dict
			.. " - add to dict     "
			.. keys.ignore_word
			.. " - ignore word",
		" "
			.. keys.undo_change
			.. " - undo            "
			.. keys.suggestions
			.. " - suggestions     "
			.. keys.toggle_preview
			.. " - toggle preview ",
		"                     " .. keys.exit_spellbound .. " - exit",
	}
	return lines
end

-- Show UI for spellcheck mode
function M.show_spellcheck_ui(keys)
	-- Create buffer for UI if it doesn't exist
	if not state.ui_bufnr or not vim.api.nvim_buf_is_valid(state.ui_bufnr) then
		state.ui_bufnr = vim.api.nvim_create_buf(false, true)
		vim.bo[state.ui_bufnr].bufhidden = "wipe"
	end

	-- Set buffer content
	local lines = create_help_content(keys)
	vim.api.nvim_buf_set_lines(state.ui_bufnr, 0, -1, false, lines)

	-- Get dimensions
	local width = 60
	local height = #lines
	local win_height = vim.api.nvim_get_option_value("lines", {})
	local win_width = vim.api.nvim_get_option_value("columns", {})

	-- Calculate position (bottom center)
	local row = win_height - height - 1
	local col = math.floor((win_width - width) / 2)

	-- Set window options
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}

	-- Create or update window
	if not state.ui_winid or not vim.api.nvim_win_is_valid(state.ui_winid) then
		state.ui_winid = vim.api.nvim_open_win(state.ui_bufnr, false, opts)

		-- Set window options
		vim.wo[state.ui_winid].winblend = 0
		vim.wo[state.ui_winid].winhighlight = "Normal:SpellcheckUI"
	else
		vim.api.nvim_win_set_config(state.ui_winid, opts)
	end
end

-- Hide UI for spellcheck mode
function M.hide_spellcheck_ui()
	if state.ui_winid and vim.api.nvim_win_is_valid(state.ui_winid) then
		vim.api.nvim_win_close(state.ui_winid, true)
		state.ui_winid = nil
	end

	-- Also hide suggestions window if it's open
	M.hide_suggestions()
end

-- Hide suggestions window
function M.hide_suggestions()
	if state.suggest_winid and vim.api.nvim_win_is_valid(state.suggest_winid) then
		vim.api.nvim_win_close(state.suggest_winid, true)
		state.suggest_winid = nil
	end
end

-- Get suggestions for misspelled word
function M.show_suggestions()
	-- Store current window
	local current_win = vim.api.nvim_get_current_win()
	state.orig_win = current_win

	-- Get current word
	local word = spell.get_current_word()

	-- Get suggestions
	local suggestions = spell.get_suggestions(word, 9)

	-- Create content for the window
	local lines = { 'Suggestions for "' .. word .. '":' }

	-- Check if there are any suggestions
	if #suggestions == 0 then
		table.insert(lines, "No suggestions found.")
	else
		-- Add numbered suggestions
		for i, suggestion in ipairs(suggestions) do
			table.insert(lines, i .. ". " .. suggestion)
		end
	end

	-- Add instructions
	table.insert(lines, "")
	table.insert(lines, "Select with number, or <Esc> to close")

	-- Create buffer for suggestions if it doesn't exist
	if not state.suggest_bufnr or not vim.api.nvim_buf_is_valid(state.suggest_bufnr) then
		state.suggest_bufnr = vim.api.nvim_create_buf(false, true)
		vim.bo[state.suggest_bufnr].bufhidden = "wipe"
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(state.suggest_bufnr, 0, -1, false, lines)

	-- Get dimensions
	local width = 50
	local height = #lines
	local win_height = vim.api.nvim_get_option_value("lines", {})
	local win_width = vim.api.nvim_get_option_value("columns", {})

	-- Calculate position (centered-ish on screen)
	local row = math.floor((win_height - height) / 2) - 5
	local col = math.floor((win_width - width) / 2)

	-- Set window options
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}

	-- Create or update window
	if not state.suggest_winid or not vim.api.nvim_win_is_valid(state.suggest_winid) then
		state.suggest_winid = vim.api.nvim_open_win(state.suggest_bufnr, true, opts)

		-- Set window options
		vim.wo[state.suggest_winid].winblend = 0
		vim.wo[state.suggest_winid].winhighlight = "Normal:SpellcheckSuggest"

		-- Set up keymaps for number selection and escape
		for i = 1, 9 do
			vim.keymap.set("n", tostring(i), function()
				if i <= #suggestions then
					-- Replace word with suggestion
					local suggestion = suggestions[i]

					-- Store the suggestion to apply
					local sugg_to_apply = suggestion

					-- Close suggestion window first to return focus to main buffer
					M.hide_suggestions()

					-- Return focus to the original window
					if state.orig_win and vim.api.nvim_win_is_valid(state.orig_win) then
						vim.api.nvim_set_current_win(state.orig_win)

						-- Apply the correction using spell module
						spell.apply_correction(sugg_to_apply)
					end
				end
			end, { buffer = state.suggest_bufnr })
		end

		-- Add escape key to close window
		vim.keymap.set("n", "<Esc>", function()
			M.hide_suggestions()
		end, { buffer = state.suggest_bufnr })
	else
		vim.api.nvim_win_set_config(state.suggest_winid, opts)
	end

	return suggestions
end

-- Toggle suggestion preview
function M.toggle_suggestion_preview()
	state.preview_enabled = not state.preview_enabled

	if state.preview_enabled then
		vim.api.nvim_echo({ { "Suggestion preview enabled", "MoreMsg" } }, false, {})
		M.show_suggestion_preview() -- Show preview for current word if it's misspelled
	else
		vim.api.nvim_echo({ { "Suggestion preview disabled", "MoreMsg" } }, false, {})
		M.hide_suggestion_preview()
	end
end

-- Show a preview of the first suggestion above a misspelled word using colorizer
function M.show_suggestion_preview()
	-- Don't show if previews are disabled by user toggle
	if not state.preview_enabled then
		return
	end

	-- Make sure the word is visible by centering the view
	vim.cmd("normal! zz")

	-- Clear any existing preview
	M.hide_suggestion_preview()

	local word = spell.get_current_word()

	-- Get first suggestion
	local suggestion = spell.get_first_suggestion(word)

	-- Only show if we have a suggestion
	if suggestion then

		-- Get cursor position
		local winid = vim.api.nvim_get_current_win()
		local bufnr = vim.api.nvim_get_current_buf()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))

		-- First check if we have valid buffer lines
		local ok, line = pcall(vim.api.nvim_buf_get_lines, bufnr, row - 1, row, false)
		if not ok or #line == 0 then
			-- This can happen if we're at the very start of the buffer
			-- or in some other edge case. Don't show preview.
			return
		end

		line = line[1]
		if not line then
			return
		end

		-- Safety check for column being out of range
		if col >= #line then
			col = #line - 1
		end
		if col < 0 then
			col = 0
		end

		-- Calculate word start and end position
		local word_start = col
		while word_start > 0 and line:sub(word_start, word_start):match("[%w']") do
			word_start = word_start - 1
		end
		if not line:sub(word_start, word_start):match("[%w']") then
			word_start = word_start + 1
		end

		local word_end = col
		while word_end < #line and line:sub(word_end + 1, word_end + 1):match("[%w']") do
			word_end = word_end + 1
		end

		-- Calculate the actual word for display
		local current_word = line:sub(word_start + 1, word_end + 1)

		-- Apply highlight to the current misspelled word (without modifying text)
		-- Exact boundary matching - no extra characters
		vim.api.nvim_buf_add_highlight(
			bufnr,
			state.color_namespace,
			"SpellcheckCurrentWord",
			row - 1,
			word_start,
			word_end
		)

		-- Get the screen position for the word
		local cursor_pos = vim.fn.screenpos(winid, row, word_start)
		if not cursor_pos or not cursor_pos.row or not cursor_pos.col then
			-- This can happen in some edge cases - don't show preview
			return
		end

		-- Create buffers for suggestion window
		state.preview_bufnr = vim.api.nvim_create_buf(false, true)

		-- Set content for suggestion buffer
		vim.api.nvim_buf_set_lines(state.preview_bufnr, 0, -1, false, { suggestion })

		-- Calculate positions for preview (above word when possible)
		local preview_row = cursor_pos.row - 2 -- Default: one line above
		local preview_col = cursor_pos.col - 1 -- Subtract 1 to align exactly with word below

		-- Special case: on first line of document show word to right instead of above
		if row == 1 then
			preview_row = cursor_pos.row - 1

			-- Fix alignment for first line case - align right after the current word
			local word_width = word_end - word_start
			preview_col = cursor_pos.col + word_width

			-- Set the indicator and content
			local arrow_text = "→ " .. suggestion
			vim.api.nvim_buf_set_lines(state.preview_bufnr, 0, -1, false, { arrow_text })

			-- Set window options for suggestion preview
			local preview_opts = {
				relative = "editor",
				width = #suggestion + 2, -- Width for the arrow and suggestion
				height = 1,
				row = preview_row,
				col = preview_col,
				style = "minimal",
				focusable = false,
				border = "none",
			}

			-- Create the floating window
			state.preview_winid = vim.api.nvim_open_win(state.preview_bufnr, false, preview_opts)

			-- Set highlights
			vim.wo[state.preview_winid].winhl = "Normal:SpellcheckSuggestion,NormalFloat:SpellcheckSuggestion"

			-- Return early as we've already created the window for this special case
			return
		end

		-- Set window options for suggestion preview (for the normal case when showing above)
		local preview_opts = {
			relative = "editor",
			width = #suggestion, -- Exact width of the suggestion text
			height = 1,
			row = preview_row,
			col = preview_col,
			style = "minimal",
			focusable = false,
			border = "none",
		}

		-- Create the floating windows
		state.preview_winid = vim.api.nvim_open_win(state.preview_bufnr, false, preview_opts)

		-- Set highlights
		vim.wo[state.preview_winid].winhl = "Normal:SpellcheckSuggestion,NormalFloat:SpellcheckSuggestion"
	end
end

-- Hide suggestion preview
function M.hide_suggestion_preview()
	-- Clear any highlights from the colorizer namespace
	local bufnr = vim.api.nvim_get_current_buf()
	pcall(vim.api.nvim_buf_clear_namespace, bufnr, state.color_namespace, 0, -1)

	-- Remove extmark if exists (keep for backward compatibility)
	if state.preview_extmark_id and state.preview_namespace then
		pcall(vim.api.nvim_buf_del_extmark, bufnr, state.preview_namespace, state.preview_extmark_id)
		state.preview_extmark_id = nil
	end

	-- Close floating window if exists
	if state.preview_winid and vim.api.nvim_win_is_valid(state.preview_winid) then
		vim.api.nvim_win_close(state.preview_winid, true)
		state.preview_winid = nil
	end

	-- Delete buffer if exists
	if state.preview_bufnr and vim.api.nvim_buf_is_valid(state.preview_bufnr) then
		vim.api.nvim_buf_delete(state.preview_bufnr, { force = true })
		state.preview_bufnr = nil
	end

	-- Note: We don't attempt to restore modified lines
	-- since we don't know what the original content was
end

-- Track initialization
local initialized = false

-- Check if UI is initialized
function M.is_initialized()
	return initialized
end

-- Setup UI module
function M.setup(config)
	if initialized then
		return
	end
	
	config = config or {}

	-- Store config
	M.config = {
		enable = config.enable ~= false,
		suggestion_preview = config.suggestion_preview ~= false,
	}

	-- Define highlight groups for UI with purple theme for the UI windows
	vim.cmd("highlight SpellcheckUI guibg=#7a4dab guifg=#FFFFFF")
	vim.cmd("highlight SpellcheckSuggest guibg=#7a4dab guifg=#FFFFFF")

	-- Define highlights for the current word (red) and suggestion (green) with custom colors
	vim.cmd("highlight! SpellcheckCurrentWord guibg=#ea3a43 guifg=#FFFFFF gui=bold")
	vim.cmd("highlight! SpellcheckSuggestion guibg=#429d40 guifg=#FFFFFF gui=bold")

	-- Force highlights to be distinct from Neovim's default spell highlights
	vim.cmd([[
	  augroup SpellboundHighlights
	    autocmd!
	    autocmd ColorScheme * highlight! SpellcheckCurrentWord guibg=#ea3a43 guifg=#FFFFFF gui=bold
	    autocmd ColorScheme * highlight! SpellcheckSuggestion guibg=#429d40 guifg=#FFFFFF gui=bold
	    autocmd ColorScheme * highlight! SpellcheckSuggest guibg=#7a4dab guifg=#FFFFFF
	    autocmd ColorScheme * highlight! SpellcheckUI guibg=#7a4dab guifg=#FFFFFF
	  augroup END
	]])

	-- Initialize color namespace if not already created
	if not state.color_namespace then
		state.color_namespace = vim.api.nvim_create_namespace("spellbound_color")
	end
	
	initialized = true
end

-- Should show UI based on config
function M.should_show_ui()
	return M.config and M.config.enable
end

return M
