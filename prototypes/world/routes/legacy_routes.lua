local legacy_routes = {}

-- Old interstellar shortcuts cut across the revised map.
-- Muria's routes are handled by seven_systems and route_reconcile.
function legacy_routes.data_final_fixes()
	deleteRoute("crucible-maraxsis")
	deleteRoute("crucible-orbit-ribbonia")
	deleteRoute("moshine-ribbonia")
	deleteRoute("igrys-orbit-ribbonia")

	deleteRoutesBetween("linox-planet_linox", "ribbonia")
	deleteRoutesBetween("linox-planet_linox", "rubia")
end

return legacy_routes
