---@diagnostic disable: undefined-field, assign-type-mismatch
-- BZ Zirconium intends lava recipes to split stone into stone and zircon, but reads the removed single category field
-- instead of categories in 2.1 (bzzirconium/vulcanus.lua:35-44).
local M = {}

local function has_metallurgy_category(categories)
	if type(categories) ~= "table" then
		return false
	end

	for _, category in pairs(categories) do
		if category == "metallurgy" then
			return true
		end
	end

	return false
end

local function has_zircon_result(results)
	for _, result in pairs(results) do
		if result.name == "zircon" then
			return true
		end
	end

	return false
end

local function note(message)
	if log then
		log("razi-protocol: bz: " .. message)
	end
end

function M.data_final_fixes()
	if not (mods and mods["bzzirconium"]) then
		return
	end

	local raw = data and data.raw or {}
	if not (raw.item or {}).zircon then
		return
	end

	for _, recipe in pairs(raw.recipe or {}) do
		if type(recipe) == "table" and type(recipe.name) == "string" and recipe.name:find("from.lava")
			and has_metallurgy_category(recipe.categories) and type(recipe.results) == "table"
			and not has_zircon_result(recipe.results) then
			local results = recipe.results
			local previous_result_count = #results
			for index, result in ipairs(results) do
				local amount = result.amount
				if result.type == "item" and result.name == "stone" and type(amount) == "number"
					and amount >= 2 and amount % 1 == 0 and result.amount_min == nil and result.amount_max == nil
					and result.probability == nil then
					local zircon_amount = math.floor(amount / 2)
					local stone_amount = amount - zircon_amount
					result.amount = stone_amount
					table.insert(results, index + 1, { type = "item", name = "zircon", amount = zircon_amount })

					if previous_result_count == 1 and recipe.main_product == nil then
						recipe.main_product = "stone"
					end

					note(recipe.name .. ": stone " .. amount .. " -> stone " .. stone_amount .. " + zircon " .. zircon_amount)
					break
				end
			end
		end
	end
end

return M
