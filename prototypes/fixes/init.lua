-- Repairs of mistakes in other mods that the player would otherwise meet: crashes, wrong values, missing data. One file
-- per repair in prototypes/fixes/<mod>/, each with a data_final_fixes(). A repair changes a
-- value only while it still has the value the source mod wrote, logs every change with "razi-protocol:" and does
-- nothing when the prototype or the mod is absent. The order below is the order of application; the list runs as the last
-- step of data-final-fixes.lua, after every other pass of this mod.
local mod_fixes = {}

local repairs = {
	require("prototypes.fixes.Krastorio2.roboport_mode_names"),
	require("prototypes.fixes.Krastorio2.loader_insert_limits"),
	require("prototypes.fixes.planetaris-arig.surface_conditions"),
	require("prototypes.fixes.Krastorio2-spaced-out.void_crushing"),
	require("prototypes.fixes.Krastorio2-spaced-out.piercing_shotgun"),
	require("prototypes.fixes.tenebris-prime.bioluminescent_copies"),
	require("prototypes.fixes.Krastorio2.construction_roboport"),
	require("prototypes.fixes.Krastorio2.artillery_range"),
}

function mod_fixes.data_final_fixes()
	for _, repair in ipairs(repairs) do
		repair.data_final_fixes()
	end
end

return mod_fixes
