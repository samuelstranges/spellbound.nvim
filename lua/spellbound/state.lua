-- Keep track of the state
State = {
	enabled = false,
	original_timeoutlen = nil,
	original_ttimeoutlen = nil,
	current_word = nil, -- Track the current misspelled word
	last_correction = nil, -- Track the last correction made {word, correction}
}

return State
