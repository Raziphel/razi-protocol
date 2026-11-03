local loader_insert_limits = {}

-- Loaders fill a machine only up to the automated insertion limit, as inserters do (respect_insert_limits).
--
-- By default a loader fills the input of a machine up to the full ingredient capacity. The crushers of Krastorio 2
-- (kr-crusher, a furnace with one input slot) take 1000 stone that way, five stacks in one slot, while their output is
-- full of sand. When a save is loaded with a changed mod set, Factorio 2.1 rebuilds the prototypes and cuts the input
-- of every furnace down to one stack: the other 800 stone of each crusher fall on the ground. Six crushers put 4800
-- stone on the ground at each mod update. Assembling machines keep their input. With the insertion limit the input
-- holds a few crafts, never more than a stack, so the load has nothing to cut. A loader still feeds a machine as fast
-- as it crafts.
--
-- The loaders of Krastorio 2 are the only loaders the player can build; the hidden ones of the base game get the same
-- flag.
function loader_insert_limits.data_final_fixes()
	for _, prototype_type in ipairs({"loader", "loader-1x1"}) do
		for name, loader in pairs(data.raw[prototype_type] or {}) do
			if loader.respect_insert_limits ~= true then
				loader.respect_insert_limits = true
				log("razi-protocol: " .. prototype_type .. " " .. name .. " respects the insertion limit of the machine it fills")
			end
		end
	end
end

return loader_insert_limits
