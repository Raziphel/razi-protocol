-- Signed and completed Skybridge contracts are force progress.
---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil, undefined-field
package.path="./?.lua;./?/init.lua;"..package.path

local function check(value,message)
	if not value then error(message,2) end
end

package.loaded["scripts.compatibility.orbital-cannon.catapult_network"]={
	snapshot=function() return {installed=false,enabled=false,entries={}} end
}
package.loaded["lib.galactic_catalog"]={system=function() return nil end}
storage={razi_great_projects={
	[1]={belts={},pending={},skybridge={from="nauvis",to="fulgora",delivered=false}},
	[3]={belts={},pending={},skybridge={from="vulcanus",to="gleba",delivered=false}},
	[4]={belts={},pending={},skybridge={from="solaris",to="umbra",delivered=false}}
}}
prototypes={entity={}}
local m=require("scripts.projects.great_projects")

m.forces_merged{source_index=1,destination_index=2}
local received=storage.razi_great_projects[2].skybridge
check(received.from=="nauvis" and received.to=="fulgora"
	and not received.delivered,
	"A signed undelivered contract should move to a force without one")
check(storage.razi_great_projects[1]==nil,"Merged source state should be removed")

m.forces_merged{source_index=3,destination_index=4}
local retained=storage.razi_great_projects[4].skybridge
check(retained.from=="solaris" and retained.to=="umbra",
	"A target force's own signed contract should be retained")

storage.razi_great_projects[5]={belts={},pending={},skybridge={
	from="vulcanus",to="gleba",delivered=true,complete=true}}
storage.razi_great_projects[6]={belts={},pending={},skybridge={
	from="nauvis",to="fulgora",delivered=false}}
m.forces_merged{source_index=5,destination_index=6}
local completed_source=storage.razi_great_projects[6].skybridge
check(completed_source.from=="vulcanus" and completed_source.to=="gleba"
	and completed_source.delivered and completed_source.complete,
	"A completed source contract should replace a target's signed contract")

storage.razi_great_projects[7]={belts={},pending={},skybridge={
	from="vulcanus",to="gleba",delivered=true,complete=true}}
local completed_target={from="nauvis",to="fulgora",delivered=true,complete=true}
storage.razi_great_projects[8]={belts={},pending={},skybridge=completed_target}
m.forces_merged{source_index=7,destination_index=8}
check(storage.razi_great_projects[8].skybridge==completed_target
	and completed_target.from=="nauvis" and completed_target.to=="fulgora",
	"When both contracts are complete, the target contract should remain unchanged")

print("Skybridge force merge: contract precedence preserved")
