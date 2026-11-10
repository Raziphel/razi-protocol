-- The Advanced Automation technology keeps the AI core gate of its recipe.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local add_technology_prerequisite_if_present = helpers.add_technology_prerequisite_if_present

local automation_ai_core = {}

function automation_ai_core.data_final_fixes()
	-- K2's advanced assembler recipe consumes AI cores, but the unlock tech does
	-- not always inherit the AI-core research gate once the full mod stack
	-- reshuffles K2 progression. Re-attach that prerequisite explicitly.
	add_technology_prerequisite_if_present("kr-automation", "kr-ai-core")
end

return automation_ai_core
