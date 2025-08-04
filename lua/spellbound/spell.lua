-- Spell operations for spellbound.nvim
local M = {}

-- Get suggestions for a word
function M.get_suggestions(word, count)
	if not word or word == "" then
		return {}
	end
	
	return vim.fn.spellsuggest(word, count or 9)
end

-- Get the first suggestion for a word
function M.get_first_suggestion(word)
	local suggestions = M.get_suggestions(word, 1)
	return suggestions[1]
end

-- Check if a word is misspelled
function M.is_misspelled(word)
	if not word or word == "" then
		return false
	end
	
	local bad_word = vim.fn.spellbadword(word)
	return bad_word[1] ~= ""
end

-- Get the current word under cursor
function M.get_current_word()
	return vim.fn.expand("<cword>")
end

-- Apply a correction to the current word
function M.apply_correction(correction)
	if not correction or correction == "" then
		return false
	end
	
	-- Use visual selection to select the word
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("viw", true, false, true), "nx", true)
	
	-- Replace with the correction
	vim.api.nvim_feedkeys('"_c' .. correction, "nx", true)
	
	return true
end

-- Navigate to next misspelled word
function M.goto_next()
	vim.cmd("normal! ]s")
end

-- Navigate to previous misspelled word
function M.goto_prev()
	vim.cmd("normal! [s")
end

-- Add word to dictionary
function M.add_to_dictionary()
	vim.cmd("normal! zg")
end

-- Ignore word in this session
function M.ignore_word()
	vim.cmd("normal! zG")
end

-- Undo last change
function M.undo()
	vim.cmd("normal! u")
end

-- Check if spell checking is enabled
function M.is_spell_enabled()
	return vim.wo.spell
end

-- Enable spell checking for current window
function M.enable_spell()
	vim.wo.spell = true
end

-- Compile spell file if needed (optimized version)
function M.compile_spellfile()
	local spellfile = vim.o.spellfile
	if not spellfile or spellfile == "" then
		return false
	end
	
	vim.cmd("silent! mkspell! " .. vim.fn.fnameescape(spellfile))
	return true
end

return M