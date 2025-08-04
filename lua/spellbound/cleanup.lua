-- Resource management and cleanup for spellbound.nvim
local M = {}

-- Registry of cleanup functions
local cleanup_functions = {}
local cleanup_id_counter = 0

-- Register a cleanup function
function M.register(cleanup_fn, description)
	cleanup_id_counter = cleanup_id_counter + 1
	local id = cleanup_id_counter
	
	cleanup_functions[id] = {
		fn = cleanup_fn,
		description = description or "cleanup function " .. id
	}
	
	-- Return unregister function
	return function()
		cleanup_functions[id] = nil
	end
end

-- Run all cleanup functions
function M.run_all()
	for id, cleanup in pairs(cleanup_functions) do
		local ok, err = pcall(cleanup.fn)
		if not ok then
			vim.notify(
				string.format("Spellbound cleanup error in %s: %s", cleanup.description, err),
				vim.log.levels.WARN
			)
		end
	end
	
	-- Clear all cleanup functions after running them
	cleanup_functions = {}
end

-- Clear all registered cleanup functions without running them
function M.clear_all()
	cleanup_functions = {}
end

-- Get count of registered cleanup functions (for debugging)
function M.count()
	local count = 0
	for _ in pairs(cleanup_functions) do
		count = count + 1
	end
	return count
end

return M