local imersite_aquilo_routes = {}

-- Imersite-Asteroids puts its inner imersite belt on the routes gleba-aquilo
-- and fulgora-aquilo (data-updates.lua:20-23), the main source of imersite on
-- the way to Aquilo. Razi Protocol deletes both routes and reaches Aquilo by
-- sye-vibrant, Muria and Rubia instead, so the belt was nowhere. Put it on
-- every route that starts or ends at Aquilo and has no imersite yet. Runs
-- after the route deletions at the end of data-final-fixes.lua.
local function has_imersite(definitions)
	for _, definition in pairs(definitions) do
		if type(definition.asteroid) == "string" and definition.asteroid:find("imersite", 1, true) then
			return true
		end
	end

	return false
end

function imersite_aquilo_routes.data_final_fixes()
	if not mods["Imersite-Asteroids"] then
		return
	end

	local ok, asteroids = pcall(require, "__Imersite-Asteroids__.imersite-asteroids-spawn-definitions")
	if not (ok and asteroids and asteroids.spawn_definitions and asteroids.inner_imersite_asteroid_belt) then
		return
	end

	for name, connection in pairs(data.raw["space-connection"] or {}) do
		if connection.from == "aquilo" or connection.to == "aquilo" then
			local definitions = connection.asteroid_spawn_definitions or {}
			if not has_imersite(definitions) then
				for _, definition in pairs(asteroids.spawn_definitions(asteroids.inner_imersite_asteroid_belt)) do
					table.insert(definitions, definition)
				end
				connection.asteroid_spawn_definitions = definitions
				log("[Razi Protocol/imersite-aquilo-routes] " .. name .. " gets the inner imersite asteroid belt")
			end
		end
	end
end

return imersite_aquilo_routes
