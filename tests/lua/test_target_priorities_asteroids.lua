---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil, param-type-mismatch, call-non-callable
-- Asteroids handed to Advanced Target Priorities (scripts/compatibility/advanced_target_priorities/asteroids.lua): every
-- asteroid name must come back from the sections the way Advanced Target Priorities 2.1.2 builds names
-- (gui/target_priority_attachment.lua:60-105: options joined by the delimiter, then prefix and suffix).
-- Run from the mod root:
--   lua5.2 tests/lua/test_target_priorities_asteroids.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local active_mods = {}
local interfaces = {}
local asteroid_prototypes = {}
rawset(_G, "script", {active_mods = active_mods})
rawset(_G, "remote", {add_interface = function(name, functions) interfaces[name] = functions end})
rawset(_G, "prototypes", {get_entity_filtered = function() return asteroid_prototypes end})

local asteroids = require("scripts.compatibility.advanced_target_priorities.asteroids")

local NAMES = {
	"small-carbonic-asteroid", "medium-carbonic-asteroid", "big-carbonic-asteroid", "huge-carbonic-asteroid",
	"small-metallic-asteroid", "huge-promethium-asteroid", "small-oxide-asteroid",
	"small-metallic_dense-asteroid", "big-metallic_dense-asteroid", "medium-oxyde_rad-asteroid",
	"small-imersite-asteroid", "huge-scrap-asteroid",
	"razi-quality-asteroid-small-carbonic-asteroid", "razi-quality-asteroid-huge-imersite-asteroid",
	"medium-rock-asteroid-planetary", "big-rock-asteroid-planetary",
	"asteroid-chunk-without-size", "small-asteroid",
}

-- The vanilla asteroid section of Advanced Target Priorities (gui/enemy_data.lua:30-40).
local function vanilla_section()
	return {
		name = "asteroids", delimiter = "-", suffix = "asteroid",
		options = {{"small", "medium", "big", "huge"}, {"oxide", "carbonic", "metallic", "promethium"}},
		option_titles = {"size", "unit_type"},
	}
end

-- Advanced Target Priorities' insert (gui/target_priority_attachment.lua:504-532).
local function apply_inserts(sections, inserts)
	for _, record in ipairs(inserts) do
		local section = sections[record.section]
		if section then
			for index, title in ipairs(section.option_titles) do
				if title == record.option_title then
					local known = false
					for _, option in ipairs(section.options[index]) do
						known = known or option == record.option
					end
					if not known then
						table.insert(section.options[index], record.option)
					end
				end
			end
		end
	end
end

-- Every name the sections can produce.
local function names_of(sections)
	local names = {}
	for _, section in pairs(sections) do
		for _, size in ipairs(section.options[1]) do
			for _, kind in ipairs(section.options[2]) do
				local name = size .. section.delimiter .. kind
				if section.prefix then
					name = section.prefix .. section.delimiter .. name
				end
				if section.suffix then
					name = name .. section.delimiter .. section.suffix
				end
				names[name] = true
			end
		end
	end
	return names
end

-- parse
local parsed = asteroids.parse("razi-quality-asteroid-huge-metallic_dense-asteroid")
check(parsed.prefix == "razi-quality-asteroid" and parsed.size == "huge" and parsed.kind == "metallic_dense"
	and parsed.suffix == "asteroid", "quality copy is parsed")
parsed = asteroids.parse("medium-rock-asteroid-planetary")
check(parsed.prefix == nil and parsed.kind == "rock" and parsed.suffix == "asteroid-planetary", "planetary is parsed")
check(asteroids.parse("small-asteroid") == nil, "a name without a kind is left out")
check(asteroids.parse("asteroid-chunk-without-size") == nil, "a name without a size is left out")

-- datasets: every readable name comes back, nothing else is added to the vanilla section
local inserts, new_sections = asteroids.datasets(NAMES)
local sections = {asteroids = vanilla_section()}
for _, section in ipairs(new_sections) do
	check(sections[section.name] == nil, "section name is unique: " .. section.name)
	sections[section.name] = section
end
apply_inserts(sections, inserts)
local produced = names_of(sections)
for _, name in ipairs(NAMES) do
	if asteroids.parse(name) then
		check(produced[name], "Advanced Target Priorities offers " .. name)
	end
end
-- the four Space Age kinds are handed over too (in case Advanced Target Priorities drops one); its insert skips doubles
local seen = {}
for _, kind in ipairs(sections.asteroids.options[2]) do
	check(not seen[kind], "no double kind " .. kind)
	seen[kind] = true
end
check(#sections.asteroids.options[2] == 8, "4 Space Age kinds and 4 more, got " .. #sections.asteroids.options[2])
check(#new_sections == 2, "one section for quality copies and one for planetary asteroids, got " .. #new_sections)
check(sections["asteroids (razi-quality)"] and sections["asteroids (planetary)"], "section names")
check(table.concat(sections["asteroids (planetary)"].options[1], ",") == "medium,big", "sizes keep their order")

-- register: only with Advanced Target Priorities, and the interface reads the game's asteroids
asteroids.register()
check(next(interfaces) == nil, "no interface without Advanced Target Priorities")
active_mods["advanced_target_priorities"] = "2.1.2"
for _, name in ipairs(NAMES) do
	asteroid_prototypes[name] = {name = name}
end
asteroids.register()
local interface = interfaces["razi-protocol-target-priorities"]
check(interface, "interface registered")
check(#interface.advanced_target_priorities_insert_section_data() == #inserts, "insert through the interface")
check(#interface.advanced_target_priorities_register_section_data() == 2, "sections through the interface")

print("test_target_priorities_asteroids: ok")
