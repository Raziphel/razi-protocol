-- Witness checks cache one surface scan per force for ten seconds.
---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
package.path="./?.lua;./?/init.lua;"..package.path

local function check(value,message)
	if not value then error(message,2) end
end

storage={}
prototypes={item={},entity={},space_location={},space_connection={}}
local m=require("scripts.convergence.convergence")
local scans=0
local active_radars={true,true,true,true,true,true,true}
local worlds={
	{"nauvis","calidus"},{"vulcanus","solaris"},{"gleba","nyxaris"},
	{"fulgora","vibrant"},{"aquilo","vespera"},{"cubium","beetlejuice"},
	{"tenebris","umbra"}
}
game={tick=10,surfaces={}}
for i,world in ipairs(worlds) do
	game.surfaces[#game.surfaces+1]={
		planet={name=world[1]},
		find_entities_filtered=function(filter)
			check(filter.name=="radar","Witness snapshot should only search for radars")
			scans=scans+1
			if active_radars[i] then return {{valid=true,energy=1}} end
			return {}
		end
	}
end
local force={index=501,get_entity_count=function(name)
	check(name=="radar","Witness snapshot should use the engine radar count")
	return #game.surfaces
end}

check(select(1,m.witness_status(force))==7,"Fresh snapshot should find all seven witnesses")
local first_scan_count=scans
check(first_scan_count==7,"Each founding system should be scanned once")
---@type any
local saved=storage.razi_convergence_witness
local snapshot=saved and saved[force.index]
check(snapshot and snapshot.tick==game.tick and snapshot.active==7
	and snapshot.total==7 and #snapshot.locations==7,
	"Witness snapshot should be saved in storage by force index")
for _,location in ipairs(snapshot.locations) do
	check(type(location.system)=="string"
		and (location.planet==nil or type(location.planet)=="string"),
		"Stored witness locations should contain only system and planet names")
	for key in pairs(location) do
		check(key=="system" or key=="planet",
			"Stored witness locations should not contain runtime objects")
	end
end

game.tick=609
check(select(1,m.witness_status(force))==7,"Cached snapshot should preserve its result")
check(scans==first_scan_count,"Checks before 600 ticks must not rescan surfaces")

-- A freshly loaded module has no Lua-local cache; it must reuse the saved table.
m=dofile("scripts/convergence/convergence.lua")
check(select(1,m.witness_status(force))==7,
	"A reloaded module should read the storage snapshot without rescanning")
check(scans==first_scan_count,
	"Reading the saved storage snapshot should not scan surfaces")

active_radars[1]=false
check(select(1,m.witness_status(force,true))==6,
	"Refresh should scan again and return the current witness count")
check(scans==first_scan_count+7,
	"Refresh should scan even while the saved snapshot is younger than 600 ticks")
local refreshed_snapshot=saved[force.index]
check(refreshed_snapshot.tick==game.tick and refreshed_snapshot.active==6,
	"Refresh should replace the stored snapshot")
check(select(1,m.witness_status(force))==6 and scans==first_scan_count+7,
	"A refresh should write a snapshot reusable by later callers")

game.tick=1208
check(select(1,m.witness_status(force))==6 and scans==first_scan_count+7,
	"A snapshot remains valid through tick 599")
active_radars[1]=true
game.tick=1209
check(select(1,m.witness_status(force))==7,
	"Expired snapshot should still find all witnesses")
check(scans==first_scan_count+14,
	"The 600-tick expiry should trigger exactly one new scan")

local previous_storage=storage
storage=nil
local uncached_force={index=502,get_entity_count=force.get_entity_count}
local scans_without_storage=scans
m.witness_status(uncached_force)
m.witness_status(uncached_force)
check(scans==scans_without_storage+14,
	"Witness checks should not cache when storage is unavailable")
storage=previous_storage

print("Convergence witness cache: storage, forced refresh, and 600-tick expiry passed")
