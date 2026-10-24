-- Names of the nests and worms of the families that share the vanilla "enemy-base" control (Armoured, Toxic and
-- Arachnids). The data stage switches them off on planets that are not their home (enemy_homes.lua); the runtime
-- (scripts/razi_enemy_surfaces.lua) does the same on surfaces made before that. Plain data: both stages load it.
return {
	armoured = {
		"armoured-biter-spawner"
	},
	arachnids = {
		"arachnid-spawner-unitspawner"
	},
	toxic = {
		"toxic-biter-spawner",
		"small-toxic-worm-turret",
		"medium-toxic-worm-turret",
		"big-toxic-worm-turret",
		"behemoth-toxic-worm-turret",
		"leviathan-toxic-worm-turret",
		"mother-toxic-worm-turret"
	}
}
