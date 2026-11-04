-- The in-game tests of razi-protocol, run by tests/load/run.sh with the FUnit mod (see contributing.md). The scenario is
-- a new freeplay map, so there is a real player with a real GUI.
-- Suites are loaded here because Factorio allows require only while this file loads. Their test functions run in the
-- Lua state of this scenario: the modules of razi-protocol they load are fresh copies of the code with their own
-- storage, not the state of the running mod, so what they prove is what that code does in the real game.
require("__base__/script/freeplay/control.lua")

local runner = require("__funit__.test_runner")
runner.register("razi-protocol")
runner.report("razi")

for _, suite in ipairs({"start", "journal", "technology", "recipes"}) do
	require("__zzz-razi-funit__.suites." .. suite)(runner)
end
