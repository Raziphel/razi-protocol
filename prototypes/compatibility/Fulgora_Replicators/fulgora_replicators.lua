local enemy_autoplace = require("prototypes.compatibility.common.enemy_autoplace")
local enemy_homes = require("prototypes.compatibility.common.enemy_homes")

if not enemy_autoplace.enabled() or not mods["Fulgora_Replicators"] then
	return
end

-- Fulgora Replicators places its islands and nests with its own autoplace control, which it adds to Fulgora in its
-- data stage (prototypes/nest.lua). With no enemy homes (Easy, or the setting at None) the new map has no replicators
-- either: the control starts at zero, which is the default of a new map, so the player can still bring it back in the
-- map settings. On every other step the control stays as the mod made it.
local control_name = "replicator_nests"

if enemy_homes.habitat() ~= "none" then
	return
end

local fulgora = data.raw.planet and data.raw.planet.fulgora
local map_gen_settings = fulgora and fulgora.map_gen_settings
if not map_gen_settings then
	return
end

map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
map_gen_settings.autoplace_controls[control_name] = {frequency = 0, size = 0}
log("razi-protocol: enemy homes: " .. control_name .. " switched off on fulgora")
