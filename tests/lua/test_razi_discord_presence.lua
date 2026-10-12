-- Razi presence: per-player opt-in, real Journal selection and local writing.
package.path="./?.lua;./?/init.lua;"..package.path
local function ok(a,msg) if not a then error(msg,2) end end
local quest_a={id="vibrant-gate",chapter="vibrant"}
local quest_b={id="asteroid-belt",chapter="vibrant"}
package.loaded["scripts.razi_journal_data"]={
  chapters={{id="calidus"},{id="vibrant"}},quests={quest_a,quest_b},
  by_id={[quest_a.id]=quest_a,[quest_b.id]=quest_b}
}
local states={[quest_a.id]="active",[quest_b.id]="active"}
package.loaded["scripts.razi_journal"]={
  context=function() return {} end,
  state=function(_,quest) return states[quest.id] end,
  next_quest=function() return quest_a end,
  summary=function() return 1,2,1 end,
  available=function() return true end,
  complete=function(_,quest) return quest.id==quest_b end
}
package.loaded["scripts.galactic_catalog"]={
  system=function(name) return name=="fulgora" and "vibrant" or "unassigned" end
}
local enabled=false
local player={
  index=1,force={index=1},physical_surface={planet={name="fulgora"}},
  mod_settings={
    ["razi-discord-presence-enabled"]={value=false},
    ["razi-discord-presence-show-quest"]={value=true},
    ["razi-discord-presence-show-location"]={value=true}
  },
  request_translation=function(value)
    ok(type(value)=="table","Journal translation request missing")
    return 42
  end
}
local files={}
rawset(_G,"storage",{})
rawset(_G,"game",{
  ticks_played=4200,connected_players={player},
  is_multiplayer=function() return false end,
  get_player=function(index) return index==1 and player end
})
rawset(_G,"helpers",{
  table_to_json=function(value) return value end,
  write_file=function(name,body,append,index)
    files[#files+1]={name=name,body=body,append=append,index=index}
  end
})
local presence=require("scripts.razi_discord_presence")
presence.write()
ok(#files==0,"Presence leaked without opt-in")
player.mod_settings["razi-discord-presence-enabled"].value=true
storage.razi_expedition_journal={
  [1]={tracker=true,pinned="asteroid-belt",selected="vibrant-gate"}
}
local state=presence.payload(player)
ok(state.quest_id=="asteroid-belt","Pinned Journal objective was ignored")
ok(state.chapter=="vibrant" and state.chapter_number==2,
  "Wrong chapter was exported")
ok(state.location=="fulgora" and state.region=="vibrant",
  "Native physical planet and system were not resolved")
ok(state.completed==1 and state.total==2,"Wrong Journal totals")
presence.on_string_translated({id=42,translated=true,
  result="Vibrant | The Broken Spectrum@@@Through the falling stones"})
state=presence.payload(player)
ok(state.chapter_title=="Vibrant | The Broken Spectrum"
  and state.quest=="Through the falling stones",
  "Localized Journal text was not cached")
presence.write()
ok(#files==1 and files[1].index==1 and files[1].append==false,
  "The export must target only the local player's file")
ok(files[1].name=="razi-presence/state.json","Wrong export filename")
player.mod_settings["razi-discord-presence-show-location"].value=false
player.mod_settings["razi-discord-presence-show-quest"].value=false
state=presence.payload(player)
ok(state.location=="" and state.quest=="",
  "Privacy settings did not suppress sensitive fields")
player.mod_settings["razi-discord-presence-enabled"].value=false
presence.on_setting_changed({
  player_index=1,setting="razi-discord-presence-enabled"
})
ok(#files==2 and files[2].body.enabled==false,
  "Turning presence off must send a clear marker")
ok(presence.payload(player)==nil,"Disabled export returned a payload")
presence.on_player_removed({player_index=1})
print("Razi per-player Discord presence exporter passed")
