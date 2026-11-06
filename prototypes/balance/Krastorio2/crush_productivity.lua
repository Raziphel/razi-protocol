local crush_productivity = {}

-- Crusher recipes (kr-crush-*) do not allow productivity, but a furnace applies the productivity of its modules to the
-- recipe it picks anyway (forums.factorio.com 131313), and the crusher has module slots in Krastorio2-spaced-out.
-- Imersite crystal -> powder -> crystal then grows. Every kr-crush-* recipe takes maximum_productivity = 0.
function crush_productivity.data_final_fixes()
	local capped = 0
	for name, recipe in pairs(data.raw.recipe) do
		if name:find("^kr%-crush%-") and recipe.maximum_productivity ~= 0 then
			recipe.maximum_productivity = 0
			capped = capped + 1
		end
	end
	log("razi-protocol: kr-crush-* recipes capped at maximum_productivity = 0: " .. capped)
end

return crush_productivity
