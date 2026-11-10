---@diagnostic disable: need-check-nil
-- The Cargo Network project in the project list: when it is visible, what its completion bar measures and what it
-- asks the player to do next.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

for _, name in ipairs({ "scripts.dyson.dyson", "scripts.convergence.convergence", "scripts.dyson.runtime", "scripts.journal.icons" }) do
	package.loaded[name] = { stages = {} }
end
package.loaded["scripts.journal.data"] = { quests = { { id = "interplanetary-trade", tech = "interplanetary-trade-logistics" } }, by_id = {} }
storage = {}
settings = { global = { ["razi-hide-spoilers"] = { value = true } } }

local research = { name = "interplanetary-trade-logistics", researched = false, localised_name = { "technology-name.x" } }
local force = { index = 5, technologies = { ["interplanetary-trade-logistics"] = research }, platforms = {} }
local projects = require("scripts.journal.projects")

check(projects.valid("cargo"), "cargo is a project")
check(projects.adjacent(force, "skybridge", 1, { "skybridge", "cargo", "beltbreaker" }) == "cargo", "cargo follows skybridge")
check(not projects.visible(force, "cargo"), "hidden until the research is done")
research.researched = true
check(projects.visible(force, "cargo"), "visible after the research")
force.technologies = {}
check(not projects.visible(force, "cargo"), "a missing technology hides the project")
force.technologies["interplanetary-trade-logistics"] = research
settings.global["razi-hide-spoilers"].value = false
check(projects.visible(force, "cargo"), "visible without the spoiler setting")

local function platform(scheduled)
	return {
		valid = true, hidden = false, scheduled_for_deletion = 0,
		schedule = scheduled and { records = { {} } } or nil,
	}
end

-- The bar counts platforms that have a schedule.
local done, total, facts = projects.status_for(force, "cargo")
check(done == 0 and total == 0 and facts.platforms == 0, "no platforms: " .. done .. "/" .. total)
force.platforms = { platform(true), platform(false), platform(true) }
done, total, facts = projects.status_for(force, "cargo")
check(done == 2 and total == 3 and facts.unscheduled == 1, "scheduled: " .. done .. "/" .. total)

-- The next step.
local function next_step(status)
	return projects.next_action(force, "cargo", status)
end
research.researched = false
local caption, quest = next_step({ projects.status_for(force, "cargo") })
check(caption[1] == "journal-ui.project-next-research" and quest == "interplanetary-trade", "research first")
research.researched = true
caption = next_step({ 0, 0, { research = research } })
check(caption[1] == "journal-ui.project-next-cargo-platform", "no platforms: build one")
caption = next_step({ projects.status_for(force, "cargo") })
check(caption[1] == "journal-ui.project-next-cargo-unscheduled" and caption[2] == "1", "one platform without a schedule")
force.platforms = { platform(true) }
caption = next_step({ projects.status_for(force, "cargo") })
check(caption[1] == "journal-ui.project-next-cargo-done", "all scheduled")

print("test_cargo_project: ok")
