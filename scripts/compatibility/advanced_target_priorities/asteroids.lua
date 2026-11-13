-- Advanced Target Priorities (heyqule) sets turret target priorities with checkboxes, section by section. Its asteroid
-- section knows the four Space Age kinds only (gui/enemy_data.lua:30-40), while a razi game has about 150 asteroid
-- prototypes: kinds of other mods, razi's quality copies (razi-quality-asteroid-<size>-<kind>-asteroid) and planetary
-- ones (<size>-<kind>-asteroid-planetary). Its interface (gui/target_priority_attachment.lua:482-535, called from its
-- on_init and on_configuration_changed) takes more options for a section and new sections; this module hands it every
-- asteroid of the game: the kinds named <size>-<kind>-asteroid go into its own asteroid section, the others into one
-- section per name pattern. A name it cannot read is left out; Advanced Target Priorities skips a combination of size
-- and kind that has no prototype.
local asteroids = {}

local INTERFACE = "razi-protocol-target-priorities"
local SECTION = "asteroids"
local SIZES = {small = true, medium = true, big = true, huge = true}
local SIZE_ORDER = {"small", "medium", "big", "huge"}

---@class AsteroidGroup
---@field prefix string?
---@field suffix string
---@field sizes table<string, true>
---@field kinds table<string, true>

---@param name string
---@return {prefix: string?, size: string, kind: string, suffix: string}?
function asteroids.parse(name)
	local tokens = {}
	for token in name:gmatch("[^%-]+") do
		tokens[#tokens + 1] = token
	end
	for index, token in ipairs(tokens) do
		if SIZES[token] then
			-- the kind runs to the next "asteroid" token, at least one token long
			for last = index + 2, #tokens do
				if tokens[last] == "asteroid" then
					local prefix = index > 1 and table.concat(tokens, "-", 1, index - 1) or nil
					return {
						prefix = prefix,
						size = token,
						kind = table.concat(tokens, "-", index + 1, last - 1),
						suffix = table.concat(tokens, "-", last, #tokens),
					}
				end
			end
			return nil
		end
	end
	return nil
end

local function sorted_keys(set)
	local list = {}
	for key in pairs(set) do
		list[#list + 1] = key
	end
	table.sort(list)
	return list
end

-- Splits asteroid names into options for the asteroid section of Advanced Target Priorities and new sections.
---@param names string[]
---@return table[] inserts, table[] sections
function asteroids.datasets(names)
	---@type table<string, true>
	local kinds = {}
	---@type table<string, AsteroidGroup>
	local groups = {}
	for _, name in ipairs(names) do
		local parsed = asteroids.parse(name)
		if parsed then
			if not parsed.prefix and parsed.suffix == "asteroid" then
				kinds[parsed.kind] = true
			else
				local key = (parsed.prefix or "") .. "|" .. parsed.suffix
				---@type AsteroidGroup
				local group = groups[key] or {prefix = parsed.prefix, suffix = parsed.suffix, sizes = {}, kinds = {}}
				groups[key] = group
				group.sizes[parsed.size] = true
				group.kinds[parsed.kind] = true
			end
		end
	end

	local inserts = {}
	for _, kind in ipairs(sorted_keys(kinds)) do
		inserts[#inserts + 1] = {section = SECTION, option_title = "unit_type", option = kind}
	end

	local sections = {}
	for _, key in ipairs(sorted_keys(groups)) do
		local group = groups[key] --[[@as AsteroidGroup]]
		local sizes = {}
		for _, size in ipairs(SIZE_ORDER) do
			if group.sizes[size] then
				sizes[#sizes + 1] = size
			end
		end
		local label = {}
		if group.prefix then
			label[#label + 1] = (string.gsub(group.prefix, "%-asteroid$", ""))
		end
		if group.suffix ~= "asteroid" then
			label[#label + 1] = (string.gsub(group.suffix, "^asteroid%-", ""))
		end
		sections[#sections + 1] = {
			name = SECTION .. " (" .. table.concat(label, ", ") .. ")",
			delimiter = "-",
			prefix = group.prefix,
			suffix = group.suffix,
			options = {sizes, sorted_keys(group.kinds)},
			option_titles = {"size", "unit_type"},
		}
	end
	return inserts, sections
end

local function game_asteroids()
	local names = {}
	for name in pairs(prototypes.get_entity_filtered({{filter = "type", type = "asteroid"}})) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

-- Registers the interface Advanced Target Priorities looks for. Without it nobody calls it.
function asteroids.register()
	if not script.active_mods["advanced_target_priorities"] then
		return
	end
	remote.add_interface(INTERFACE, {
		advanced_target_priorities_insert_section_data = function()
			local inserts = asteroids.datasets(game_asteroids())
			return inserts
		end,
		advanced_target_priorities_register_section_data = function()
			local _, sections = asteroids.datasets(game_asteroids())
			return sections
		end,
	})
end

return asteroids
