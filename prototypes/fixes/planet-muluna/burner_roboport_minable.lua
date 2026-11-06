local burner_roboport_minable = {}

-- The burner roboport of Muluna is a copy of the vanilla roboport that mines into the vanilla roboport item
-- (prototypes/entity/burner-roboport.lua:1 copies minable.result unchanged), and
-- prototypes/final-fixes/burner-roboports.lua:199-217 takes the result of the K2 mode copies, which have no item of their
-- own, from the roboport they were made of: the logistic and construction modes of the burner roboport (and the hidden
-- roboports behind them) mine into a roboport, 45 advanced circuits and 20 steel beams instead of the 45 circuits and
-- 45 steel plates of the burner roboport. The modes mine into the burner roboport.
local names = {
	"muluna-burner-roboport-logistic-mode", "muluna-burner-roboport-construction-mode",
	"muluna-burner-roboport-logistic-mode-roboport", "muluna-burner-roboport-construction-mode-roboport",
}

function burner_roboport_minable.data_final_fixes()
	if not (data.raw.item and data.raw.item["muluna-burner-roboport"]) then
		return
	end

	for _, name in ipairs(names) do
		for _, type_name in ipairs({"assembling-machine", "roboport"}) do
			local entity = data.raw[type_name] and data.raw[type_name][name]
			if entity and entity.minable and entity.minable.result == "roboport" then
				entity.minable.result = "muluna-burner-roboport"
				log("razi-protocol: " .. name .. " mines into the burner roboport")
			end
		end
	end
end

return burner_roboport_minable
