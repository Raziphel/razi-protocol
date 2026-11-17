---@diagnostic disable: need-check-nil
-- The Skybridge project shows from Vulcanus on, long before the catapult research: its next step names that research
-- or its missing prerequisite first, then asks for the catapults.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

for _, name in ipairs({ "scripts.dyson.dyson", "scripts.convergence.convergence", "scripts.dyson.runtime", "scripts.journal.icons" }) do
	package.loaded[name] = { stages = {} }
end
package.loaded["scripts.journal.data"] = { quests = { { id = "rubia", tech = "planet-discovery-rubia" } }, by_id = {} }
storage = {}
settings = { global = { ["razi-hide-spoilers"] = { value = false } } }

local rubia = { name = "planet-discovery-rubia", researched = false, localised_name = { "technology-name.rubia" } }
local catapult = {
	name = "razi-orbital-catapult", researched = false, localised_name = { "technology-name.catapult" },
	prerequisites = { ["planet-discovery-rubia"] = rubia },
}
local force = { index = 1, technologies = { ["razi-orbital-catapult"] = catapult, ["planet-discovery-rubia"] = rubia } }
local projects = require("scripts.journal.projects")

local function next_step()
	return projects.next_action(force, "skybridge", { 0, 3, { options = {} } })
end

local caption, quest = next_step()
check(caption[1] == "journal-ui.project-next-prerequisite" and caption[2] == rubia.localised_name and quest == "rubia",
	"a missing prerequisite comes first, got " .. tostring(caption[1]))

rubia.researched = true
caption = next_step()
check(caption[1] == "journal-ui.project-next-research" and caption[2] == catapult.localised_name,
	"then the catapult research, got " .. tostring(caption[1]))

catapult.researched = true
caption = next_step()
check(caption[1] == "journal-ui.project-next-skybridge-build", "then the catapults, got " .. tostring(caption[1]))

-- Without the razi catapult technology the project asks for the machines as before.
force.technologies["razi-orbital-catapult"] = nil
caption = next_step()
check(caption[1] == "journal-ui.project-next-skybridge-build", "no technology: build, got " .. tostring(caption[1]))

print("test_skybridge_next_step: ok")
