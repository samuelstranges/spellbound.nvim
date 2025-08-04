-- State management for spellbound.nvim
local M = {}

-- Private state storage
local state = {
	enabled = false,
	original_timeoutlen = nil,
	original_ttimeoutlen = nil,
	current_word = nil,
	last_correction = nil,
	preview_timer = nil,
}

-- Event listeners
local listeners = {}

-- Get a state value
function M.get(key)
	return state[key]
end

-- Set a state value and notify listeners
function M.set(key, value)
	local old_value = state[key]
	if old_value == value then
		return -- No change
	end
	
	state[key] = value
	
	-- Notify listeners
	M.emit("state_changed", key, old_value, value)
	M.emit("state_changed:" .. key, value, old_value)
end

-- Batch update multiple state values
function M.update(updates)
	for key, value in pairs(updates) do
		M.set(key, value)
	end
end

-- Reset state to defaults
function M.reset()
	for key, _ in pairs(state) do
		if key ~= "enabled" then
			state[key] = nil
		end
	end
	state.enabled = false
	M.emit("state_reset")
end

-- Add an event listener
function M.on(event, callback)
	if not listeners[event] then
		listeners[event] = {}
	end
	table.insert(listeners[event], callback)
	
	-- Return unsubscribe function
	return function()
		M.off(event, callback)
	end
end

-- Remove an event listener
function M.off(event, callback)
	if not listeners[event] then
		return
	end
	
	for i, cb in ipairs(listeners[event]) do
		if cb == callback then
			table.remove(listeners[event], i)
			break
		end
	end
end

-- Emit an event
function M.emit(event, ...)
	if not listeners[event] then
		return
	end
	
	for _, callback in ipairs(listeners[event]) do
		local ok, err = pcall(callback, ...)
		if not ok then
			vim.notify("Spellbound state event error: " .. err, vim.log.levels.ERROR)
		end
	end
end

-- Get all state (for debugging)
function M.get_all()
	return vim.deepcopy(state)
end

-- Backward compatibility (direct access)
M.enabled = false
M.original_timeoutlen = nil
M.original_ttimeoutlen = nil
M.current_word = nil
M.last_correction = nil

-- Set up metatable for backward compatibility
setmetatable(M, {
	__index = function(t, key)
		-- Check if it's a function first
		local value = rawget(t, key)
		if value ~= nil then
			return value
		end
		-- Otherwise return from state
		return state[key]
	end,
	__newindex = function(t, key, value)
		-- Check if it's a module function
		if type(value) == "function" then
			rawset(t, key, value)
		else
			-- Otherwise set in state
			state[key] = value
		end
	end
})

return M