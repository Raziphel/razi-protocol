local M = {}

-- Chapter references from the 248k-Redux 2.1.51 measurement: fission uses nuclear-reactor (250 MW),
-- fusion uses kr-advanced-steam-turbine (200 MW), and gravitation uses kr-antimatter-reactor (3 GW).
-- The black-hole interface gets script-controlled production, so its output flow is capped at that gravitation reference
-- (248k-Redux/prototypes/gravitation/gr_black_hole.lua:64-78; 248k-Redux/scripts/gravitation/gr_black_hole_script.lua:327-341).
local caps = {
	{
		type = "electric-energy-interface",
		name = "gr_black_hole_energy",
		path = "energy_source.output_flow_limit",
		from = nil,
		to = "3GW",
	},
}

local function note(message)
	if log then
		log("razi-protocol: 248k: " .. message)
	end
end

local function field_at_path(prototype, path)
	local current = prototype
	local parent
	local key

	for segment in path:gmatch("[^%.]+") do
		if type(current) ~= "table" then
			return nil, nil, nil
		end
		parent = current
		key = segment
		current = current[key]
	end

	return current, parent, key
end

local function display(value)
	if value == nil then
		return "nil"
	end
	return tostring(value)
end

function M.data_final_fixes()
	if not (mods and mods["248k-Redux"]) then
		return
	end

	for _, cap in ipairs(caps) do
		local prototypes = data.raw[cap.type] or {}
		local prototype = prototypes[cap.name]
		if prototype then
			local current, parent, key = field_at_path(prototype, cap.path)
			if parent and current == cap.from then
				parent[key] = cap.to
				note("set " .. cap.name .. " " .. cap.path .. " to " .. cap.to)
			else
				note(cap.name .. " " .. cap.path .. " is " .. display(current)
					.. ", expected " .. display(cap.from) .. ", left as is")
			end
		end
	end
end

return M
