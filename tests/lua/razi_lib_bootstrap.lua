-- Make Factorio's __razi_lib__/ module paths available to standalone Lua tests.
local library_root = os.getenv("RAZI_LIB_PATH") or "../RaziLib"
package.path = library_root .. "/?.lua;" .. package.path

local native_require = require
function require(name)
  return native_require((name:gsub("^__razi_lib__/", "")))
end
