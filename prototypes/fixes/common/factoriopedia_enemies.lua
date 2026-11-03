local factoriopedia_enemies = {}

-- Enemy mods make their units as deep copies of vanilla ones and keep the copied factoriopedia_simulation, which creates
-- the vanilla unit by name (base prototypes/factoriopedia-simulations.lua:256-278, make_enemy). Factoriopedia then shows a
-- small biter for an arachnid drone, a medium biter for every fake human of Big-Monsters, a vanilla pentapod for its
-- wrigglers. A unit whose simulation creates exactly one entity, another unit, creates itself instead.
function factoriopedia_enemies.data_final_fixes()
	local fixed = 0
	for name, unit in pairs(data.raw.unit or {}) do
		local simulation = unit.factoriopedia_simulation
		local init = simulation and simulation.init

		if type(init) == "string" then
			local _, creations = init:gsub("create_entity", "")
			local created = init:match('create_entity%s*{%s*name%s*=%s*"([^"]+)"')

			if creations == 1 and created and created ~= name and data.raw.unit[created] then
				-- Units copied from one another may share the simulation table: each gets its own.
				local copy = table.deepcopy(simulation)
				if copy then
					local replacement = "%1" .. name:gsub("%%", "%%%%") .. "%2"
					copy.init = init:gsub('(create_entity%s*{%s*name%s*=%s*")[^"]+(")', replacement, 1)
					unit.factoriopedia_simulation = copy
					fixed = fixed + 1
				end
			end
		end
	end

	if fixed > 0 then
		log("razi-protocol: factoriopedia simulations that showed another unit, now show their own: " .. fixed)
	end
end

return factoriopedia_enemies
