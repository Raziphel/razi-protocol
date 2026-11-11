local hidden_prerequisites = {}

-- A technology that needs a hidden technology can never be researched. frozeta-nuclear-winter 1.12.7 without Dea Dia
-- hides the long, fast and bulk heat inserter technologies of heat-inserter and moves their recipes to the heat inserter
-- technology (data-updates.lua:46-80), while heat-inserter's neodymium bulk heat inserter still needs the bulk one
-- (prototypes/technology.lua:137); PlanetsLib reports it as unresearchable. A hidden prerequisite gives way to the
-- visible technologies that now unlock its recipes, or, when none does, to its own prerequisites. A replacement that
-- itself needs the technology would make a cycle and is skipped.
local function visible(technologies, name)
	local technology = technologies[name]
	return technology and not technology.hidden
end

local function unlocked_by(technologies)
	local result = {}
	for name, technology in pairs(technologies) do
		if not technology.hidden then
			for _, effect in ipairs(technology.effects or {}) do
				if effect.type == "unlock-recipe" and effect.recipe then
					result[effect.recipe] = result[effect.recipe] or {}
					table.insert(result[effect.recipe], name)
				end
			end
		end
	end
	for _, names in pairs(result) do
		table.sort(names)
	end
	return result
end

-- Whether research of `from` needs `target` somewhere among its prerequisites.
local function needs(technologies, from, target, seen)
	if from == target then return true end
	if seen[from] then return false end
	seen[from] = true
	local technology = technologies[from]
	for _, prerequisite in ipairs(technology and technology.prerequisites or {}) do
		if needs(technologies, prerequisite, target, seen) then return true end
	end
	return false
end

-- The visible technologies that stand for a hidden one: those that unlock its recipes, else its own prerequisites
-- (resolved the same way when they are hidden too).
local function replacements(technologies, recipe_unlocks, hidden, seen)
	if seen[hidden] then return {} end
	seen[hidden] = true
	local result, added = {}, {}
	local function add(name)
		if not added[name] then
			added[name] = true
			result[#result + 1] = name
		end
	end
	for _, effect in ipairs(technologies[hidden].effects or {}) do
		if effect.type == "unlock-recipe" then
			for _, name in ipairs(recipe_unlocks[effect.recipe] or {}) do
				add(name)
			end
		end
	end
	if #result > 0 then return result end
	for _, prerequisite in ipairs(technologies[hidden].prerequisites or {}) do
		if visible(technologies, prerequisite) then
			add(prerequisite)
		elseif technologies[prerequisite] then
			for _, name in ipairs(replacements(technologies, recipe_unlocks, prerequisite, seen)) do
				add(name)
			end
		end
	end
	return result
end

function hidden_prerequisites.data_final_fixes()
	local technologies = data.raw.technology or {}
	local recipe_unlocks = unlocked_by(technologies)
	local names = {}
	for name in pairs(technologies) do
		names[#names + 1] = name
	end
	table.sort(names)

	for _, name in ipairs(names) do
		local technology = technologies[name]
		local prerequisites = technology.prerequisites
		if not technology.hidden and prerequisites then
			local result, kept, changed = {}, {}, false
			local function keep(prerequisite)
				if not kept[prerequisite] then
					kept[prerequisite] = true
					result[#result + 1] = prerequisite
				end
			end
			for _, prerequisite in ipairs(prerequisites) do
				local other = technologies[prerequisite]
				if other and other.hidden then
					changed = true
					local used = {}
					for _, replacement in ipairs(replacements(technologies, recipe_unlocks, prerequisite, {})) do
						if not needs(technologies, replacement, name, {}) then
							keep(replacement)
							used[#used + 1] = replacement
						end
					end
					log("razi-protocol: " .. name .. " needed the hidden technology " .. prerequisite .. ", now "
						.. (#used > 0 and table.concat(used, ", ") or "nothing in its place"))
				else
					keep(prerequisite)
				end
			end
			if changed then
				technology.prerequisites = result
			end
		end
	end
end

return hidden_prerequisites
