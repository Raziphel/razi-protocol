-- Imersite asteroid crushing waits for the discovery of Fulgora now
-- (prototypes/compatibility/Imersite-Asteroids/crushing_gate.lua). In a save where it is the current research before
-- Fulgora, the game takes it off the queue after the migrations and drops its progress with it. The migrations still
-- see that progress: this one takes the research off the queue itself and keeps the progress on the technology, so
-- it continues once Fulgora is discovered.
local M = {}

M.technology = "imersite-asteroid-crushing"

local function researchable(technology)
	for _, prerequisite in pairs(technology.prerequisites) do
		if not prerequisite.researched then
			return false
		end
	end
	return true
end

function M.run()
	for _, force in pairs(game.forces) do
		local technology = force.technologies[M.technology]
		local current = force.current_research
		if technology and not technology.researched and current and current.name == M.technology
			and not researchable(technology) then
			local progress = force.research_progress
			local queue = {}
			for _, queued in ipairs(force.research_queue) do
				if queued.name ~= M.technology then
					queue[#queue + 1] = queued.name
				end
			end
			force.research_queue = queue
			technology.saved_progress = progress
			log("razi-protocol: " .. M.technology .. " leaves the research queue of " .. force.name
				.. " until Fulgora is discovered, its progress " .. progress .. " is kept")
		end
	end
end

return M
