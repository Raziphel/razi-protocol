-- The Rubia long stack inserter requires the long stack inserter.
local helpers = require("prototypes.fixes.common.progression_helpers")
local technology = helpers.technology
local add_prerequisite = helpers.add_prerequisite

local long_stack_inserter = {}

function long_stack_inserter.data_final_fixes()
	local rubia_long_stack = technology("rubia-long-stack-inserter")
	if not rubia_long_stack then
		return
	end

	add_prerequisite(rubia_long_stack, "long-stack-inserter")
end

return long_stack_inserter
