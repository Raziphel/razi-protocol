---@diagnostic disable: need-check-nil
-- The Cargo Network overview page: the fleet line, the guide line, one block per corridor. A corridor with a
-- world that is not researched does not name it.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local snapshots = 0
local network
package.loaded["scripts.compatibility.orbital-cannon.catapult_network"] = {
	snapshot = function()
		snapshots = snapshots + 1
		return network
	end,
}
local inspected
package.loaded["scripts.cargo.infrastructure"] = {
	inspect = function(_, worlds)
		inspected = worlds
		return { nauvis = { launchers = 2, platforms = 1 } }
	end,
}
local view = require("scripts.cargo.view")

local function node(shown)
	local element = { style = {} }
	function element.add(spec)
		if spec.caption then
			shown[#shown + 1] = spec.caption
		end
		return node(shown)
	end
	return element
end
local function render(facts)
	local shown = {}
	view.render(node(shown), { force = { platforms = {}, technologies = {} } }, 400, facts)
	return shown
end
local function has(shown, key, argument)
	for _, caption in ipairs(shown) do
		if type(caption) == "table" and caption[1] == "journal-ui." .. key and (argument == nil or caption[2] == argument) then
			return caption
		end
	end
	return nil
end

local facts = { platforms = 3, unscheduled = 1, in_transit = 2 }

network = { installed = false, enabled = false, entries = {} }
local shown = render(facts)
check(has(shown, "cargo-fleet-counts", "3") and has(shown, "cargo-unscheduled-note"), "the fleet line and the note")
check(has(shown, "cargo-corridors-absent") and has(shown, "project-cargo-guide"), "no mod: one line and the guide")

network = { installed = true, enabled = false, entries = {} }
check(has(render(facts), "cargo-corridors-off"), "corridors off")

network = { installed = true, enabled = true, entries = {} }
check(has(render(facts), "cargo-corridors-none"), "no corridors")

network = {
	installed = true, enabled = true,
	entries = {
		{ source = "nauvis", target = "vulcanus", state = "researched" },
		{ source = "gleba", target = "moshine", state = "unresearched" },
	},
}
snapshots = 0
shown = render({ platforms = 1, unscheduled = 0, in_transit = 0 })
check(snapshots == 1, "one catapult snapshot per drawing, got " .. snapshots)
check(not has(shown, "cargo-unscheduled-note"), "no note when every platform has a schedule")
check(#inspected == 2 and inspected[1] == "nauvis" and inspected[2] == "vulcanus", "only the open corridor is inspected")
check(has(shown, "cargo-corridor"), "the open corridor is named")
local with_machines = has(shown, "cargo-end")
check(with_machines and with_machines[3] == "2" and with_machines[4] == "1", "machines found at the end with a surface")
check(has(shown, "cargo-end-no-surface"), "an end without a surface says so")
check(has(shown, "cargo-corridor-closed"), "a closed corridor has one line")
for _, caption in ipairs(shown) do
	check(type(caption) ~= "table" or caption[1] ~= "journal-ui.cargo-corridor" or caption[2][1] ~= "space-location-name.gleba",
		"the closed corridor names its world")
end

print("test_cargo_view: ok")
