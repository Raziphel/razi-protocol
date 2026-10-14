"""Razi's native Space Age manager must remain opt-in and read-only."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class GalacticOperationsTests(unittest.TestCase):
    def test_native_deep_space_atlas_dossiers_are_read_only(self):
        atlas=(ROOT/"scripts/galactic_atlas.lua").read_text()
        gui=(ROOT/"scripts/galactic_operations.lua").read_text()
        strings=(ROOT/"locale/en/galactic_operations.cfg").read_text()
        for destination in ("solar-system-edge","shattered-planet",
                            "nexus","razi-deep-space-edge",
                            "black-hole-approach"):
            self.assertIn('["'+destination+'"]',atlas)
        self.assertIn("brief and convergence.available(player.force)",atlas)
        self.assertIn('razi_ops_action="atlas-convergence"',atlas)
        self.assertIn('if action=="atlas-convergence" then',gui)
        self.assertIn("M.open_convergence(player)",gui)
        self.assertNotIn("create_surface",atlas)
        for key in ("atlas-convergence-heading","atlas-convergence-edge",
                    "atlas-convergence-shattered","atlas-convergence-nexus",
                    "atlas-convergence-frontier","atlas-convergence-approach",
                    "atlas-convergence-open"):
            self.assertIn(key+"=",strings)

    def test_atlas_industry_reverse_index_is_cached(self):
        atlas=(ROOT/"scripts/galactic_atlas.lua").read_text()
        code=(ROOT/"control.lua").read_text()
        self.assertIn("local industry_by_parent",atlas)
        self.assertIn("function M.related_industries(force,research)",atlas)
        self.assertIn("for id,tech in pairs(prototypes.technology)",atlas)
        self.assertIn("local industries=M.related_industries(",atlas)
        self.assertNotIn("for _,tech in pairs(player.force.technologies or {})",atlas)
        self.assertIn("technology and not technology.researched",code)
        self.assertIn("force.get_entity_count(active_transceiver_name)>0",code)

    def test_gui_is_opt_in_and_event_based(self):
        control=(ROOT/"control.lua").read_text()
        ui=(ROOT/"scripts/galactic_operations.lua").read_text()
        self.assertIn('galactic_operations.sync_all_map_buttons',control)
        self.assertIn('on_player_controller_changed',control)
        self.assertIn('events:on_nth_tick(30, function(event)',control)
        self.assertIn('galactic_operations.sync_all_map_buttons(event)',control)
        self.assertNotIn('on_lua_shortcut',control)
        self.assertIn('on_gui_text_changed',control)
        self.assertIn('on_gui_selection_state_changed',control)
        self.assertIn('PAGE_SIZE=16',ui)
        self.assertIn('razi_ops_role_filter',ui)
        self.assertIn('razi_ops_role_',ui)
        self.assertIn('p.roles[id]',ui)
        self.assertIn('prototypes.space_location',ui)
        self.assertIn('player.force.platforms',ui)
        self.assertNotIn('on_nth_tick',ui)
        self.assertNotIn('create_surface(',ui)
        self.assertNotIn('create_space_platform(',ui)
        self.assertNotIn('game_view_settings.show_surface_list',ui)
    def test_keyboard_shortcut_and_locale(self):
        proto=(ROOT/"prototypes/ui/galactic_operations.lua").read_text()
        loc=(ROOT/"locale/en/galactic_operations.cfg").read_text()
        self.assertNotIn('type="shortcut"',proto)
        self.assertIn('type="sprite"',proto)
        self.assertIn('razi-galactic-operations-map-icon',proto)
        ui=(ROOT/"scripts/galactic_operations.lua").read_text()
        self.assertIn('MAP_ANCHOR="razi_ops_map_anchor"',ui)
        self.assertIn('type="sprite-button",name=MAP_BUTTON',ui)
        self.assertIn('player.render_mode~=defines.render_mode.game',ui)
        self.assertIn('player.controller_type==defines.controllers.remote',ui)
        self.assertNotIn('set_shortcut_toggled',ui)
        self.assertIn('CONTROL + SHIFT + G',proto)
        self.assertIn('[razi-ops]',loc)
        self.assertIn('group-vibrant=',loc)
    def test_atlas_fleet_are_read_only(self):
        ui=(ROOT/"scripts/galactic_operations.lua").read_text()
        atlas=(ROOT/"scripts/galactic_atlas.lua").read_text()
        fleet=(ROOT/"scripts/galactic_fleet.lua").read_text()
        self.assertIn('atlas.render(inspector,player,id,p)',ui)
        self.assertIn('fleet.render(inspector,platform,id,p)',ui)
        self.assertIn('razi_ops_note_id',ui)
        self.assertIn('shortest_path',atlas)
        self.assertIn('unlock-space-location',atlas)
        self.assertIn('can_leave_current_location()',fleet)
        self.assertIn('defines.inventory.hub_main',fleet)
        for source in (atlas,fleet):
            self.assertNotIn('create_surface(',source)
            self.assertNotIn('on_nth_tick',source)
            self.assertNotIn('platform.schedule=',source)
    def test_map_and_atlas_performance_guards(self):
        operations=(ROOT/"scripts/galactic_operations.lua").read_text()
        atlas=(ROOT/"scripts/galactic_atlas.lua").read_text()
        self.assertIn('if not current or current.x~=x or current.y~=86 then',operations)
        self.assertIn('local search=lower(p.search or "")',operations)
        self.assertIn('local recent={}',operations)
        self.assertIn('row.sort_name=lower(row.display_search or row.name)',operations)
        self.assertIn('row.sort_group=catalog.position(row.group)',operations)
        self.assertIn('local function location_research_catalog()',atlas)
        self.assertIn('local function connection_index()',atlas)
        self.assertIn('local function accessible(name)',atlas)
        self.assertNotIn('script.on_nth_tick',atlas)

    def test_responsive_cards_and_localized_search(self):
        operations=(ROOT/"scripts/galactic_operations.lua").read_text()
        locale=(ROOT/"locale/en/galactic_operations.cfg").read_text()
        control=(ROOT/"control.lua").read_text()
        self.assertIn('function M.layout(resolution,scale)',operations)
        self.assertIn('local compact=outer<860',operations)
        self.assertIn('type="table",name="razi_ops_tabs"',operations)
        self.assertIn('column_count=layout.compact and 3 or 6',operations)
        self.assertIn('type="frame",direction="vertical",style="inside_shallow_frame"',operations)
        self.assertIn('sprite=row_sprite(row)',operations)
        self.assertIn('helpers.is_valid_sprite_path(source)',operations)
        self.assertIn('row.display_search or ""',operations)
        self.assertIn('row.location_search or ""',operations)
        self.assertIn('player.request_translation(caption)',operations)
        self.assertIn('function M.on_string_translated(event)',operations)
        self.assertIn('p.translation_dirty=true',operations)
        self.assertIn('p.translation_requested[name]=true',operations)
        self.assertIn('galactic_operations.on_string_translated(event)',control)
        self.assertIn('razi_discord_presence.on_string_translated(event)',control)
        self.assertIn('search-translating=',locale)
        self.assertIn('clear-search=',locale)
        for section in ('list-title-worlds','list-title-platforms',
                        'stat-total','stat-matches','stat-transit','stat-attention',
                        'fleet-more-warnings'):
            self.assertIn(section+'=',locale)

    def test_actions_and_saved_preferences_remain(self):
        code=(ROOT/"scripts/galactic_operations.lua").read_text()
        for key in ('p.favorites','p.roles','p.notes','p.recent',
                    'p.atlas_origin','p.priority_sort'):
            self.assertIn(key,code)
        self.assertIn('row.alerts[i]',code)
        self.assertIn('frame.razi_ops_search_tools.visible=listing',code)
        self.assertIn('frame.razi_ops_options.visible=value=="worlds"',code)
        self.assertIn('player.set_controller{type=defines.controllers.remote',code)
        self.assertIn('p.search="";p.page=1',code)
        self.assertNotIn('create_surface(',code)
        self.assertNotIn('create_space_platform(',code)

    def test_cargo_network_dashboard_uses_actual_source_content(self):
        trade=(ROOT/"scripts/galactic_trade.lua").read_text()
        listing=(ROOT/"scripts/galactic_trade_catalog.lua").read_text()
        source=(ROOT/"prototypes/compat/network_components.lua").read_text()
        ops=(ROOT/"scripts/galactic_operations.lua").read_text()
        locale=(ROOT/"locale/en/galactic_operations.cfg").read_text()
        self.assertIn('trade.render(body,player,p)',ops)
        self.assertIn('action=="cargo-focus"',ops)
        self.assertIn('p.cargo_focus=p.cargo_focus==value and nil or value',ops)
        self.assertIn('for _,entry in ipairs(M.chains)',listing)
        self.assertIn('if state.status~="absent" then',listing)
        self.assertIn('tech.prerequisites or {}',listing)
        self.assertIn('catalog.snapshot(player.force)',trade)
        self.assertIn('prototypes.recipe[part.id]',trade)
        self.assertIn('sprite_for("item",entry.id)',trade)
        self.assertIn('source_worlds(card,entry,width-20)',trade)
        self.assertIn('supplier_recipe(card,entry,width-20)',trade)
        self.assertIn('consumers(card,row,width-20,p)',trade)
        self.assertIn('scroll.horizontal_scroll_policy="never"',trade)
        self.assertIn('column_count=size.compact and 1 or 2',trade)
        self.assertIn('trade-research-not-production',trade)
        self.assertNotIn('platform.schedule=',trade)
        self.assertNotIn('create_surface(',trade)
        self.assertNotIn('on_nth_tick(',trade)
        for name in (
            "razi-network-precision-matrix",
            "razi-network-panglia-optic-bond",
            "razi-network-extreme-lattice",
            "razi-network-umbra-pressure-frame",
        ):
            self.assertIn(f'id="{name}"',listing)
            self.assertIn(f'name="{name}"',source)
        for name in (
            "razi-network-matrix-cryo-controllers",
            "razi-network-matrix-rubia-logistics",
            "razi-network-matrix-linox-refining",
            "razi-network-bond-paracelsin-coils",
            "razi-network-bond-linox-refining",
            "razi-network-lattice-vesta-magnets",
            "razi-network-lattice-vesta-foundations",
            "razi-network-lattice-balack-shielding",
            "razi-network-frame-vesta-foundations",
            "razi-network-frame-aquilo-controllers",
        ):
            self.assertIn(f'"{name}"',listing)
            self.assertIn(f'upgrade("{name}"',source)
        for key in ("trade-state-researched","trade-state-ready",
                    "trade-state-blocked","trade-no-components",
                    "trade-chain-bond","trade-chain-frame",
                    "trade-yield","trade-dispatch-guide"):
            self.assertIn(key+"=",locale)

    def test_codex_cargo_deep_links_keep_save_data_read_only(self):
        catalog=(ROOT/"scripts/galactic_trade_catalog.lua").read_text()
        codex=(ROOT/"scripts/razi_journal.lua").read_text()
        operations=(ROOT/"scripts/galactic_operations.lua").read_text()
        cargo=(ROOT/"scripts/galactic_trade.lua").read_text()
        for helper in ("chain_for_technology","quest_for_technology",
                       "chain_for_quest","is_installed"):
            self.assertIn("function M."+helper+"(",catalog)
        self.assertIn('function M.open_quest(player,id)',codex)
        self.assertIn('razi_journal_action="open-cargo"',codex)
        self.assertIn('cargo_catalog.chain_for_quest(quest.id)',codex)
        self.assertIn('function M.open_cargo(player,chain,target)',operations)
        self.assertIn('p.cargo_focus=chain',operations)
        self.assertIn('p.cargo_target=target',operations)
        self.assertIn('p.cargo_direct=not M.in_map_view(player)',operations)
        self.assertIn('p.cargo_origin=chain',operations)
        self.assertIn('p.cargo_direct and p.tab=="trade"',operations)
        self.assertIn('action=="cargo-codex"',operations)
        self.assertIn('journal.open_quest(player,quest_id)',operations)
        self.assertIn('M.open_cargo(player,chain,target)',operations)
        self.assertIn('razi_ops_action="cargo-codex"',cargo)
        self.assertIn('p.cargo_target==consumer.name',cargo)
        self.assertIn('p.cargo_target==entry.id',cargo)
        self.assertNotIn("player.set_controller",catalog)
        self.assertNotIn("create_surface(",cargo)
        self.assertNotIn("platform.schedule=",operations)
        self.assertNotIn("data:extend",catalog)

    def test_cargo_cards_show_actual_science_requirements(self):
        panel=(ROOT/"scripts/galactic_trade.lua").read_text()
        locale=(ROOT/"locale/en/galactic_operations.cfg").read_text()
        self.assertIn("local function science_requirements(parent,tech,width)",panel)
        self.assertIn("tech.research_unit_ingredients",panel)
        self.assertIn("tech.research_unit_count",panel)
        self.assertIn("science_requirements(card,row.technology,width-20)",panel)
        self.assertIn("science_requirements(parent,consumer.technology,width)",panel)
        self.assertIn("if p.cargo_focus==entry.id then",panel)
        self.assertIn("p.cargo_target==consumer.name",panel)
        self.assertIn('sprite_for("item",name)',panel)
        self.assertNotIn("force.current_research=",panel)
        for key in ("trade-science-heading","trade-science-units",
                    "trade-science-more"):
            self.assertIn(key+"=",locale)
        self.assertEqual(locale.count("trade-components="),1)

    def test_all_seven_systems(self):
        catalog=(ROOT/"scripts/galactic_catalog.lua").read_text()
        for star in ("calidus","solaris","nyxaris","vibrant","vespera","beetlejuice","umbra"):
            self.assertIn(star,catalog)
if __name__=="__main__":
    unittest.main()
