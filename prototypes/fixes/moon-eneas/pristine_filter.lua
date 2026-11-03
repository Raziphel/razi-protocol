local orphan_unlocks = require("prototypes.fixes.common.orphan_unlocks")

local pristine_filter = {}

local base_name = "filter-heavy-oil-pristine"
local copy_prefix = base_name .. "__rigor_module_mod__"

-- moon-eneas 1.0.10 (prototypes/entity/environment.lua:644) gives the pristine heavy oil filter coal with
-- amount_min = 5 above amount_max = 1; the plain filter (:615) has 1 to 5. The range is put the right way round, in
-- the recipe and in the hidden rigor-module copies made from it (they carry the coal result unchanged).
local function put_range_right()
	for name, recipe in pairs(data.raw.recipe or {}) do
		if name == base_name or name:sub(1, #copy_prefix) == copy_prefix then
			for _, product in pairs(recipe.results or {}) do
				if product.name == "coal" and product.amount_min and product.amount_max
					and product.amount_min > product.amount_max then
					product.amount_min, product.amount_max = product.amount_max, product.amount_min
					log("razi-protocol: " .. name .. " makes " .. product.amount_min .. " to " .. product.amount_max
						.. " coal, not the other way round")
				end
			end
		end
	end
end

-- moon-eneas 1.0.10 makes the pristine heavy oil filter (prototypes/entity/environment.lua:629) next to the plain
-- one, which water-advanced unlocks (prototypes/technology.lua:771), and unlocks it nowhere. pristine-servofish
-- unlocks the pristine servofish and the other pristine filter (prototypes/technology.lua:687-688); the recipe runs in
-- the same water purification machines as that filter.
function pristine_filter.data_final_fixes()
	put_range_right()
	orphan_unlocks.unlock(base_name, "pristine-servofish")
end

return pristine_filter
