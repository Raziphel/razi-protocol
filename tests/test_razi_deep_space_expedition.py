"""Deep Space Convergence gate must be based on real navigable visits."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
class DeepSpaceExpedition(unittest.TestCase):
    def test_final_ignition_requires_all_actual_crew_stops(self):
        runtime=read("scripts/razi_convergence.lua")
        self.assertIn('local visited,required,_,chart_ready=M.expedition_status(force)',runtime)
        self.assertIn('return false,"convergence-need-deep-chart"',runtime)
        self.assertIn('return false,"convergence-need-deep-expedition"',runtime)
        self.assertIn('local landed,required,stops,chart_ready=M.expedition_status(force)',runtime)
        self.assertIn('convergence-deep-tour-arrived',runtime)
        self.assertIn('convergence-deep-tour-missing',runtime)
        self.assertIn('if not M.location(player) then return "convergence-need-platform",0 end',runtime)
        self.assertIn('inv.remove{name=rule.item,count=offered}',runtime)

    def test_real_prototype_graph_and_in_person_arrivals(self):
        source=read("scripts/razi_deep_space_expedition.lua")
        for snippet in (
            'prototypes.space_connection',
            'function M.targets()',
            'while index<=#queue do',
            'if proto and visited[name] and not proto.hidden then',
            'player.controller_type==defines.controllers.remote',
            'player.character and player.character.valid',
            'platform.force==player.force',
            '(platform.completed_trips or 0)>0',
            'storage.razi_deep_space_visits',
            'function M.forces_merged(event)',
            'function M.observe_connected(platform)'
        ): self.assertIn(snippet,source)
        for name in ('solar-system-edge','razi-deep-space-edge','shattered-planet',
                     'nexus','black-hole-approach','black-hole','oort-cloud','sol',
                     'skewer_shattered_planet','skewer_lost_beyond'):
            self.assertIn('"'+name+'"',source)
        self.assertNotIn('script.on_tick',source)
        self.assertNotIn('create_space_platform',source)

    def test_event_and_guide_wiring(self):
        ctrl=read("control.lua")
        for event in ('on_player_changed_surface','on_player_controller_changed',
                      'on_space_platform_changed_state'):
            self.assertIn('defines.events.'+event,ctrl)
        self.assertIn('deep_expedition.observe_connected(event.platform)',ctrl)
        self.assertIn('deep_expedition.observe_connected()',ctrl)
        self.assertIn('deep_expedition.forces_merged(event)',ctrl)
        ops=read("locale/en/galactic_operations.cfg")
        for key in ('convergence-need-deep-chart','convergence-need-deep-expedition',
                    'convergence-deep-tour-heading','convergence-deep-tour-count',
                    'convergence-deep-tour-arrived','convergence-deep-tour-missing'):
            self.assertIn(key+'=',ops)
        ui=read("locale/en/razi_journal_interface.cfg")
        self.assertIn('project-next-convergence-deep-tour=',ui)
        self.assertIn('project-next-convergence-chart=',ui)

    def test_legacy_victory_is_preserved(self):
        source=read("scripts/razi_convergence.lua")
        self.assertIn('if saved.victory then return #M.stages+1 end',source)
        self.assertIn('if saved.victory then return #M.stages,#M.stages,true end',source)
        self.assertIn('if saved.victory then return end',source)
        self.assertIn('can_continue=true',source)
if __name__=="__main__":
    unittest.main()
