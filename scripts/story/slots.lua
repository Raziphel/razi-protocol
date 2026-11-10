-- The text slots of the storyline.
--
-- A slot is one place where the journal, Projects, Convergence or the welcome
-- shows authored text. Each kind of slot reads one section of one
-- locale/en/story-*.cfg file, and the key inside the section is the id of the
-- quest, chapter, record and so on (docs/story-slots.md lists them all).
--
-- `length` is the longest text, in characters, that fits its field in the
-- window at 1920x1080 and 100 % interface scale without scrolling. It is an
-- estimate from the field width and the lines the window leaves free.
--
-- `stub` is false for a slot whose text names something in a list. Writer
-- mode shows the game's own name there (for a record, its id), so the list
-- stays usable, and the slot key is available through the key tooltip.
local M={}

M.files={"story-quests","story-chapters","story-records","story-projects",
  "story-welcome","story-finale"}

M.kinds={
  ["quest-title"]={file="story-quests",section="razi-story-quest-title",
    where="quest name in the list and the dossier heading",length=60,stub=false},
  ["quest-story"]={file="story-quests",section="razi-story-quest",
    where="quest dossier, story block",length=900},
  ["quest-tip"]={file="story-quests",section="razi-story-quest-tip",
    where="quest dossier, field note",length=400},
  ["quest-brief"]={file="story-quests",section="razi-story-quest-brief",
    where="quest dossier, industrial brief",length=400},
  ["quest-charter"]={file="story-quests",section="razi-story-quest-charter",
    where="quest dossier, field assignment",length=500},
  ["chapter-mood"]={file="story-chapters",section="razi-story-chapter-mood",
    where="line under the chapter name",length=90},
  ["chapter-summary"]={file="story-chapters",section="razi-story-chapter-summary",
    where="chapter cover, summary",length=500},
  ["chapter-dispatch"]={file="story-chapters",section="razi-story-chapter-dispatch",
    where="chapter cover, dispatch",length=400},
  ["chapter-context"]={file="story-chapters",section="razi-story-chapter",
    where="chapter cover, context",length=600},
  ["chapter-star"]={file="story-chapters",section="razi-story-chapter-star",
    where="chapter cover, star charter",length=300},
  ["record-title"]={file="story-records",section="razi-story-record-title",
    where="Archive list and record heading",length=60,stub=false},
  ["record-origin"]={file="story-records",section="razi-story-record-origin",
    where="Archive record, line under the heading",length=80},
  ["record-body"]={file="story-records",section="razi-story-record",
    where="Archive record, text",length=2500},
  ["project-context"]={file="story-projects",section="razi-story-project",
    where="Projects, line under the project overview",length=300},
  ["welcome"]={file="story-welcome",section="razi-story-welcome",
    where="chat message when a player first joins",length=200},
  ["finale-testimony"]={file="story-finale",section="razi-story-finale-testimony",
    where="Convergence, witness network",length=250},
  ["finale-blackbox"]={file="story-finale",section="razi-story-finale-blackbox",
    where="Convergence, recovered black box",length=300},
  ["finale-beat"]={file="story-finale",section="razi-story-finale-beat",
    where="Convergence, transmission line",length=60},
  ["finale"]={file="story-finale",section="razi-story-finale",
    where="Convergence, final panel",length=400},
}

-- Kinds in the order of the slot list.
M.order={"quest-title","quest-story","quest-tip","quest-brief","quest-charter",
  "chapter-mood","chapter-summary","chapter-dispatch","chapter-context",
  "chapter-star","record-title","record-origin","record-body",
  "project-context","welcome","finale-testimony","finale-blackbox",
  "finale-beat","finale"}

-- Locale key of a slot: the section plus the id.
function M.key(kind,id)
  local slot=M.kinds[kind]
  return slot and slot.section.."."..id or nil
end

return M
