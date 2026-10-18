-- Recovered Codex transmissions, unlocked by their matching research.
local records={
 {id="reception",unlock="first-signal",origin="SURVEY LOG / CALIDUS"},
 {id="moon",unlock="muluna",origin="ASTRONOMICAL DIVISION / MULUNA"},
 {id="furnace",unlock="castra",origin="INDUSTRIAL RECOVERY / CASTRA"},
 {id="living",unlock="moshine",origin="DATA DIVISION / MOSHINE"},
 {id="scar",unlock="cerys",origin="RESTORATION CREW / CERYS"},
 {id="belt",unlock="asteroid-belt",origin="CONVOY BLACK BOX / FIRST DIVIDE"},
 {id="ocean",unlock="seadragon",origin="DEEP-WATER REPORT / MARAXSIS"},
 {id="shadow",unlock="tenebris",origin="BIOLOGICAL REPORT / TENEBRIS"},
 {id="network",unlock="precision-matrix",origin="TRADE ARCHIVE / FOUR-WORLD STANDARD"},
 {id="sphere",unlock="dyson-build",origin="STELLAR WORKS / CALIDUS"},
 {id="threshold",unlock="outer-mastery",origin="RESTRICTED SCIENCE DIVISION / DEEP SPACE"},
 {id="answer",unlock="stable-singularity",origin="LAST ARCHIVE ENTRY / TRANSMISSION READY"},
 {id="nexus-signal",unlock="nexus-whisper",origin="NEXUS SURVEY / THE FIRST BEACON"},
 {id="nexus-nine",unlock="nexus-convergence",origin="NEXUS EXPEDITION / THE THIRD CIRCLE"},
 {id="nexus-silence-record",unlock="nexus-silence",origin="NEXUS ARCHIVE / THE SILENCED TRANSMISSION"},
}
-- Preserve legacy IDs; append independent source-milestone-gated records.
for _,entry in ipairs(require("scripts.razi_journal_corporate")) do
  records[#records+1]=entry
end
return records
