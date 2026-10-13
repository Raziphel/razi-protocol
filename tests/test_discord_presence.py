"""Static protocol and source-ownership checks for Razi Presence."""
import pathlib
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]

class DiscordPresenceTests(unittest.TestCase):
    def test_opt_in_and_local_client_routing(self):
        settings=(ROOT/"settings.lua").read_text()
        code=(ROOT/"scripts/razi_discord_presence.lua").read_text()
        self.assertIn('name="razi-discord-presence-enabled"',settings)
        self.assertIn('setting_type="runtime-per-user",default_value=false',settings)
        self.assertIn('helpers.write_file(FILE,helpers.table_to_json(payload)',code)
        self.assertIn('false,player.index)',code)
        self.assertIn('if allowed(player) then',code)
        self.assertIn('razi_expedition_journal',code)
        self.assertIn('journal.next_quest',code)
        self.assertIn('journal.summary',code)
        self.assertIn('player.request_translation',code)
        self.assertNotIn('socket.',code)

    def test_runtime_handlers_and_companion(self):
        control=(ROOT/"control.lua").read_text()
        bridge=(ROOT/"tools/razi-presence.js").read_text()
        self.assertIn('events:on_nth_tick(900, razi_discord_presence.write)',control)
        self.assertIn('razi_discord_presence.on_string_translated',control)
        self.assertIn('razi_discord_presence.on_setting_changed',control)
        self.assertIn('razi_discord_presence.on_player_removed',control)
        for module in ('node:fs','node:net','node:os','node:path'):
            self.assertIn('require("'+module+'")',bridge)
        self.assertIn('cmd:"SET_ACTIVITY"',bridge)
        self.assertIn('this.send(0,{v:1,client_id:this.id})',bridge)
        self.assertIn('razi-logo',bridge)
        self.assertNotIn('https.request',bridge)
        self.assertNotIn('child_process',bridge)

if __name__=="__main__":
    unittest.main()
