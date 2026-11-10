local corpse_names = {}

-- Arachnids_enemy names its corpses by keys it never defines (prototypes/arachnids.lua:200-272 of 1.2.1, locale/en
-- has none of them): hovering the corpse of a bug hole or of any bug or spitter read "Unknown key:
-- entity-name.arachnid-unitspawner-corpse" in every language. The keys are in locale/*/arachnids.cfg of this mod now.
-- The leviathan corpse and the ten boss corpses are copies of the royal warrior corpse (data.lua:154 and :319) and kept
-- its name, though the mod has keys for both (locale/en/locale.cfg:15 and :18), so they take those.
local copied_name = "entity-name.arachnid-royalwarrior-corpse"

local function take_name(corpse, key)
	local current = corpse.localised_name
	if type(current) == "table" and current[1] == copied_name and current[2] == nil then
		corpse.localised_name = {key}
		log("razi-protocol: " .. corpse.name .. " reads " .. key .. " instead of the name of the royal warrior corpse")
	end
end

function corpse_names.data_final_fixes()
	local corpses = data.raw.corpse
	if not corpses then
		return
	end

	if corpses["arachnid-leviathan-corpse"] then
		take_name(corpses["arachnid-leviathan-corpse"], "entity-name.arachnid-leviathan-corpse")
	end
	for k = 1, 10 do
		local corpse = corpses["corpse-maf-boss-arachnid-biter-" .. k]
		if corpse then
			take_name(corpse, "entity-name.maf-boss-arachnid-corpse")
		end
	end
end

return corpse_names
