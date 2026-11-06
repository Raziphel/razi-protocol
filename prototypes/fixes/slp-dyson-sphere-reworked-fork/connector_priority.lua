local connector_priority = {}

-- The Dyson sphere connectors of slp-dyson-sphere-reworked-fork (ds-energy-small-loader, ds-energy-loader-mk1..3) are
-- electric energy interfaces that feed the power of the sphere into the network with usage_priority = "tertiary"
-- (prototypes/dyson-sphere.lua:157, 292, 338, 384), the priority of accumulators: the network takes their power only after
-- every generator, and they charge accumulators last. They give power as a generator does, primary-output
-- (checked by the author of the report:
-- mods.factorio.com/mod/slp-dyson-sphere-reworked/discussion/6a37182c3d7667ecbea2fe56).
function connector_priority.data_final_fixes()
	for name, interface in pairs(data.raw["electric-energy-interface"] or {}) do
		local source = interface.energy_source
		if name:find("^ds%-energy%-") and source and source.usage_priority == "tertiary" then
			source.usage_priority = "primary-output"
			log("razi-protocol: " .. name .. " usage_priority = primary-output")
		end
	end
end

return connector_priority
