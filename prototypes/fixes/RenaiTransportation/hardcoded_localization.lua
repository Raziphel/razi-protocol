local hardcoded_localization = {}

-- RenaiTransportation sets a localised_name on every thrower it makes, its item and its recipe
-- (data-final-fixes.lua:476-479, 504-507, 536-539), built from the name of the inserter it was made from. A name set
-- that way hides the entries of the locale files for these prototypes (entity-name.RTThrower-<inserter>,
-- item-name.RTThrower-<inserter>-Item, recipe-name.RTThrower-<inserter>-Recipe), including the ones Renai itself ships
-- for some languages. Each of the six prototypes of the base inserters reads its own locale key first and keeps the name
-- Renai built as the fallback, so a language with no such key shows what it showed before.
local throwers = {
	"bulk-inserter",
	"burner-inserter",
	"fast-inserter",
	"inserter",
	"long-handed-inserter",
	"stack-inserter",
}

local function find_named_prototype(prototype_types, name)
	for type_name in pairs(prototype_types or {}) do
		local prototypes = data.raw[type_name]
		if prototypes and prototypes[name] then
			return prototypes[name]
		end
	end
end

-- Only the name that Renai wrote changes: {"?", <name with "Thrower __1__">, <fallback>}.
local function set_locale_name(prototype, section, name)
	local current = prototype and prototype.localised_name
	local key = section .. "." .. name
	local done = type(current) == "table" and type(current[2]) == "table" and current[2][1] == key
	if type(current) == "table" and current[1] == "?" and not done then
		prototype.localised_name = {"?", {key}, current}
		log("razi-protocol: " .. name .. " reads " .. key .. " before the name Renai built")
	end
end

function hardcoded_localization.data_final_fixes()
	for _, suffix in ipairs(throwers) do
		local entity_name = "RTThrower-" .. suffix
		local item_name = entity_name .. "-Item"
		local recipe_name = entity_name .. "-Recipe"

		set_locale_name(find_named_prototype(defines.prototypes.entity, entity_name), "entity-name", entity_name)
		set_locale_name(find_named_prototype(defines.prototypes.item, item_name), "item-name", item_name)
		set_locale_name(data.raw.recipe and data.raw.recipe[recipe_name], "recipe-name", recipe_name)
	end
end

return hardcoded_localization
