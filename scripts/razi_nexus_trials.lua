-- Read-only bridge to the source-owned Nexus Bosses progression.
-- Its remote snapshot is provided by the boss mod. One call per Journal view,
-- no polling, no boss entity scanning, and no mutation of the source's state.
local M={}
M.order={
  "arachnid-queen","watcher","rogue-spidertron",
  "twin-maws","colossus","plague-hulk",
  "storm-guardian","devourer","last-commander"
}
function M.snapshot(force)
  if not (force and remote and remote.interfaces
    and remote.interfaces["nexus-bosses"]
    and remote.interfaces["nexus-bosses"].get_state) then return nil end
  local ok,snapshot=pcall(remote.call,"nexus-bosses","get_state")
  if not ok or type(snapshot)~="table"
    or type(snapshot.defeated)~="table" then return nil end
  local defeated=snapshot.defeated[force.name] or {}
  local count=0
  for _,id in ipairs(M.order) do
    if defeated[id]==true then count=count+1 end
  end
  return {defeated=defeated,count=count,total=#M.order}
end
function M.defeated(snapshot,id)
  return snapshot and snapshot.defeated and snapshot.defeated[id]==true or false
end
function M.open_codex(player,id)
  if not (player and remote and remote.interfaces
    and remote.interfaces["nexus-bosses"]
    and remote.interfaces["nexus-bosses"].open_codex) then return false end
  -- Explicit player interaction only; the source mod renders its own Codex.
  local ok=pcall(remote.call,"nexus-bosses","open_codex",player.index,id)
  return ok
end
return M
