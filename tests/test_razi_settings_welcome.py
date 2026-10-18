"""Full Razi settings visual consistency and new-map onboarding checks."""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def contents(name):
    return (ROOT/name).read_text(encoding="utf-8")

def section(text,title):
    match=re.search(r"^\["+re.escape(title)+r"\]\n(.*?)(?=^\[|\Z)",
                    text,re.M|re.S)
    return dict(re.findall(r"^([^=\s]+)=(.*)$",match.group(1),re.M)) if match else {}

def settings_names(src):
    return set(re.findall(r'startup_toggle\(\s*"(razi-[^"]+)"',src)) | set(
        re.findall(r'\bname\s*=\s*"(razi-[^"]+)"',src))

class WelcomeAndSettingsTests(unittest.TestCase):
    def test_every_setting_has_consistent_category_styling(self):
        ids=settings_names(contents("settings.lua"))
        self.assertGreaterEqual(len(ids),62)
        for language in ("en","ru"):
            locale=contents(f"locale/{language}/settings.cfg")
            labels=section(locale,"mod-setting-name")
            description=section(locale,"mod-setting-description")
            self.assertTrue(ids.issubset(labels),
                            f"{language}: missing labels {ids-set(labels)}")
            self.assertTrue(ids.issubset(description),
                            f"{language}: missing descriptions {ids-set(description)}")
            self.assertEqual(section(locale,"mod-name").get("razi-protocol"),
                             "Razi Protocol")
            for name in ids:
                self.assertTrue(labels[name].startswith("[color=#"),
                                f"{language}: unstyled {name}")
                self.assertIn("[/color]",labels[name])
                self.assertLessEqual(len(re.sub(r"\\[[^]]+\\]","",labels[name])),80,
                                     f"{language}: long label {name}")
                self.assertLessEqual(len(description[name]),260,
                                     f"{language}: long description {name}")

    def test_journal_visibility_controls_are_wired(self):
        source=contents("settings.lua")
        journal=contents("scripts/razi_journal.lua")
        control=contents("control.lua")
        for name in ("razi-journal-show-button","razi-journal-show-tracker"):
            self.assertIn(name,source)
            self.assertIn(name,journal)
            self.assertIn(name,control)
        self.assertIn('top.destroy()',journal)
        self.assertIn('if player then razi_journal.sync(player) end',control)

    def test_research_and_welcome_default_options(self):
        raw=contents("settings.lua")
        for name in ("razi-hide-spoilers","razi-hide-other-tech-spoilers",
                     "razi-clean-startup-chat","razi-show-welcome"):
            match=re.search(r'name="'+name+r'"([^}]+)\}',raw,re.S)
            self.assertIsNotNone(match,name)
            self.assertIn("default_value=true",match.group(1))
        self.assertIn('setting_type="runtime-global"',raw)
        self.assertIn('setting_type="runtime-per-user"',raw)

    def test_welcome_is_first_arrival_only_and_opt_out_safe(self):
        lua=contents("scripts/razi_welcome.lua")
        self.assertIn("NEW_MAP_LIMIT=600",lua)
        self.assertIn("player.clear_console()",lua)
        self.assertIn("if early and game.tick<=NEW_MAP_LIMIT",lua)
        self.assertIn('option(player,"razi-clean-startup-chat")',lua)
        self.assertIn('option(player,"razi-show-welcome")',lua)
        self.assertIn("if s.seen[player.index] then return end",lua)
        self.assertIn("function M.command(event)",lua)
        self.assertNotIn("game.print(",lua)
        self.assertNotIn("on_tick",lua)
        control=contents("control.lua")
        self.assertIn('commands.add_command("razi-welcome"',control)
        self.assertIn("welcome.on_player_created(player)",control)
        self.assertIn("welcome.on_player_joined(player)",control)
        self.assertIn("welcome.flush()",control)
        self.assertNotIn("razi_safe_cheat.admin_tip(player)",control)

    def test_welcome_localization_and_links(self):
        locale=section(contents("locale/en/razi_welcome.cfg"),"razi-welcome")
        for key in ("header","intro","journal","links","admin","command-help"):
            self.assertTrue(locale.get(key),key)
        self.assertIn("https://razisrealm.com",locale["links"])
        self.assertIn("https://wiki.razisrealm.com",locale["links"])
        self.assertIn("https://razisrealm.com/discord",locale["links"])
        self.assertIn("Ctrl+Shift+J",locale["journal"])
        for key in ("identification","status-initial","status-local",
                    "status-flight","status-network","status-commission"):
            self.assertTrue(locale.get(key),key)
        self.assertIn("__1__",locale["journal"])
        self.assertIn("function M.signal(player)",
                      contents("scripts/razi_welcome.lua"))
        self.assertIn("unread_count(player.index)",
                      contents("scripts/razi_welcome.lua"))

    def test_manual_ci_keeps_expanded_regression_suite(self):
        workflow=contents(".github/workflows/check.yml")
        self.assertIn("workflow_dispatch:",workflow)
        self.assertNotIn("\n  push:",workflow)
        self.assertIn("test_razi_welcome.lua",workflow)
        self.assertIn("test_razi_spoiler_fog.lua",workflow)

if __name__=="__main__":
    unittest.main()
