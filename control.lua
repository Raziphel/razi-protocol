local Events = require("__razi_lib__/runtime/events")
local voidcraft_variants = require("scripts.compatibility.Voidcraft.variants")
local target_priorities = require("scripts.compatibility.advanced_target_priorities.asteroids")
local entities = require("scripts.events.entities")
local damage = require("scripts.events.damage")

local events = Events.new()

-- Handlers of one event run in the order they are registered, so the order of this list matters: the transceiver
-- poll comes before the Journal upkeep on the 600-tick timer, the cheat helper before the Journal on a player joining.
require("scripts.events.lifecycle").register(events)
entities.register(events)
damage.register(events)
require("scripts.events.cheat").register(events)
require("scripts.events.asteroids").register(events)
require("scripts.events.players").register(events)
require("scripts.events.journal").register(events)
require("scripts.events.convergence").register(events)
require("scripts.events.platforms").register(events)
require("scripts.events.forces").register(events)

require("scripts.events.commands").register()

-- Voidcraft 2.11.1 hands the unlock of its recipe variants to this interface instead of walking every recipe on each research.
voidcraft_variants.register()
-- Advanced Target Priorities offers every asteroid of the game, not only the four of Space Age.
target_priorities.register()

events:install()

entities.set_filters()
damage.set_filters()
