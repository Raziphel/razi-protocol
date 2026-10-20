"""UI-focused regressions for the five RP3 difficulty choices."""
import json
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def text(path):
    return (ROOT/path).read_text(encoding="utf-8")

class DifficultyUILabels(unittest.TestCase):
    def test_normal_is_default_and_custom_is_last(self):
        settings=text("settings.lua")
        self.assertRegex(settings,r'name="razi-difficulty-preset",\s*setting_type="startup",default_value="normal"')
        self.assertIn('allowed_values={"easy","normal","hard","nightmare","custom"}',settings)

    def test_labels_are_only_mode_names(self):
        options={
            "en":{"easy":"Easy","normal":"Normal","hard":"Hard",
                  "nightmare":"Nightmare","custom":"Custom"},
            "ru":{"easy":"Лёгкая","normal":"Обычная","hard":"Сложная",
                  "nightmare":"Кошмар","custom":"Своя"}
        }
        for lang,labels in options.items():
            body=text("locale/"+lang+"/settings.cfg")
            for key,value in labels.items():
                with self.subTest(lang=lang,mode=key):
                    pattern=r"^razi-difficulty-preset-"+key+r"=(.*)$"
                    match=re.search(pattern,body,re.MULTILINE)
                    self.assertIsNotNone(match)
                    self.assertEqual(match.group(1),value)
            self.assertIn("[mod-setting-description]",body)
            self.assertIn("razi-difficulty-preset=",body)
    def test_bumped_version_for_installed_mod_distinction(self):
        self.assertEqual(json.loads(text("info.json"))["version"],"2.1.131")
if __name__=="__main__":
    unittest.main()
