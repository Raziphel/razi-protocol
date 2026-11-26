---@diagnostic disable: undefined-field

local train_types = { "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" }
local yir_name_patterns = {
	"^yir_",
	"^y_",
	"^bioluminescent%-yir_",
	"^bioluminescent%-y_",
}

local function is_yir_train(name)
	for _, pattern in ipairs(yir_name_patterns) do
		if name:match(pattern) then
			return true
		end
	end
	return false
end

local function has_gravity_minimum(conditions)
	for _, condition in pairs(conditions or {}) do
		if condition.property == "gravity" and condition.min and condition.min >= 1 then
			return true
		end
	end
	return false
end

local function equal(left, right)
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end
	for key, value in pairs(left) do
		if not equal(value, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

return function(runner)
	if not script.active_mods["yi_railway"] then return end

	runner.test("YIR does not nerf the vanilla locomotive", function()
		local setting = settings.startup["yir_vanilla_loco_nerf"]
		runner.assert(setting and setting.value == false, "yir_vanilla_loco_nerf is not false")
	end)

	runner.test("YIR industrial coke gives 20 MJ", function()
		local coke = prototypes.item["yir_fuel_coks"]
		runner.assert(coke and coke.fuel_value == 20000000,
			"yir_fuel_coks has fuel value " .. tostring(coke and coke.fuel_value))
	end)

	runner.test("YIR rolling stock follows the vanilla space train rules", function()
		local found = 0
		local broken = {}
		for prototype_name, prototype in pairs(prototypes.entity) do
			if prototype.type and is_yir_train(prototype.name or prototype_name) then
				for _, train_type in ipairs(train_types) do
					if prototype.type == train_type then
						found = found + 1
						local vanilla = prototypes.entity[train_type]
						if not vanilla then
							broken[#broken + 1] = train_type .. " has no vanilla prototype"
						elseif script.active_mods["nuclear-steps"] then
							if not equal(prototype.tile_buildability_rules, vanilla.tile_buildability_rules) then
								broken[#broken + 1] = prototype.name .. " does not follow the vanilla tile buildability rules"
							end
						elseif not has_gravity_minimum(prototype.surface_conditions) then
							broken[#broken + 1] = prototype.name .. " has no gravity condition with min >= 1"
						end
					end
				end
			end
		end
		runner.assert(found > 0, "no YIR rolling stock found")
		runner.assert(#broken == 0, table.concat(broken, "; "))
	end)

	runner.test("YIR u1 and u3 fuel recipes make their named fuels", function()
		for _, name in ipairs({"yir_fuel_fluid_u1", "yir_fuel_fluid_u3"}) do
			local recipe = prototypes.recipe[name]
			local product = recipe and recipe.products and recipe.products[1]
			runner.assert(product and product.type == "item" and product.name == name,
				name .. " does not produce its named item first")
		end
	end)
end
