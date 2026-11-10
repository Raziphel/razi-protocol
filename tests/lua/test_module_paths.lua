---@diagnostic disable: need-check-nil, param-type-mismatch
-- Every module named in a require exists. A migration runs only on an old save, and a missing module there stops the
-- load of that save while new maps, tests and data dumps all pass, so this reads the files instead of running them.
local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local ROOTS = {prototypes = true, scripts = true, lib = true, settings = true}

local function exists(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		return true
	end
	return false
end

local missing, seen = {}, 0
local pipe = io.popen("find . -type f -name '*.lua' -not -path './.git/*'")
check(pipe, "Cannot list the Lua files")
for path in pipe:lines() do
	local file = io.open(path, "r")
	check(file, "Cannot read " .. path)
	local text = file:read("*a")
	file:close()
	for _, pattern in ipairs({'require%s*%(?%s*"([^"]+)"', "require%s*%(?%s*'([^']+)'"}) do
		for name in text:gmatch(pattern) do
			local root = name:match("^([%w_]+)[%./]")
			-- a name that ends in a dot is the start of a concatenated path: a test builds those
			if ROOTS[root] and not name:find("%.$") then
				seen = seen + 1
				local target = (name:gsub("%.", "/"))
				if not exists(target .. ".lua") and not exists(target .. "/init.lua") then
					missing[#missing + 1] = path .. " -> " .. name
				end
			end
		end
	end
end
pipe:close()

check(seen > 500, "Expected the scan to see the requires of the mod, saw " .. seen)
check(#missing == 0, "Modules that do not exist:\n" .. table.concat(missing, "\n"))

print("test_module_paths: ok")
