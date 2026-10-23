"""Keep Razi's journal useful, readable and save-compatible.

This checks the authored English copy. It does not attempt to grade style
mechanically or verify Factorio's runtime locale renderer.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(path):
    out = {}
    section = None
    for line in (ROOT / path).read_text(encoding="utf-8").splitlines():
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            out.setdefault(section, {})
        elif section and line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            if key in out[section]:
                raise AssertionError(f"Duplicate {section}.{key} in {path}")
            out[section][key] = value
    return out


class JournalCopyContracts(unittest.TestCase):
    def test_journal_story_and_title_ids_stay_in_sync(self):
        stories = load("locale/en/razi_journal_stories.cfg")["journal-story"]
        titles = load("locale/en/razi_journal_titles.cfg")["journal-title"]
        tips = load("locale/en/razi_journal_field_notes.cfg")["journal-tip"]
        self.assertEqual(262, len(stories))
        self.assertEqual(set(stories), set(titles))
        self.assertTrue(set(tips).issubset(stories))
        self.assertTrue(all(value.strip() for value in stories.values()))
        self.assertTrue(all(value.strip() for value in titles.values()))

    def test_chapters_and_charters_stay_complete(self):
        chapters = load("locale/en/razi_journal_chapters.cfg")
        for key in ("journal-chapter-summary", "journal-chapter-story",
                    "journal-chapter-dispatch"):
            self.assertEqual(set(chapters["journal-chapter"]), set(chapters[key]))
        charter = load("locale/en/razi_planet_charters.cfg")
        self.assertEqual(set(charter["razi-planet-charter"]),
                         set(charter["razi-planet-freight"]))
        names = load("locale/en/names.cfg")
        self.assertGreaterEqual(len(names["razi-location-briefing"]), 91)
        self.assertIn("aegis", names["razi-expedition-heading"])

    def test_archives_remain_real_documents_not_missing_placeholders(self):
        for file in ("locale/en/razi_journal_corporate.cfg",
                     "locale/en/razi_journal_transmissions.cfg"):
            sections = load(file)
            titles = sections["journal-record-title"]
            origins = sections["journal-record-origin"]
            bodies = sections["journal-record-body"]
            self.assertEqual(set(titles), set(origins))
            self.assertEqual(set(titles), set(bodies))
            self.assertTrue(all(len(text) > 35 for text in bodies.values()))
        records = load("locale/en/razi_journal_corporate.cfg")["journal-record-body"]
        joined = " ".join(records.values())
        for name in ("Rhea Calder", "Noor Halden", "BLACKOUT-SEVEN"):
            self.assertIn(name, joined)

    def test_editorial_cliches_are_not_reintroduced(self):
        fields = [
            load("locale/en/names.cfg")["razi-location-briefing"],
            load("locale/en/razi_journal_stories.cfg")["journal-story"],
            load("locale/en/razi_journal_chapters.cfg")["journal-chapter-story"],
        ]
        text = " ".join(value.lower() for field in fields for value in field.values())
        for phrase in ("a testament to", "not merely", "more than just",
                       "the expedition learns", "what it means to",
                       "in a world where"):
            with self.subTest(phrase=phrase):
                self.assertNotIn(phrase, text)

    def test_current_starmap_facts_in_field_notes(self):
        fields = load("locale/en/names.cfg")["razi-location-briefing"]
        self.assertIn("Ribbonia", fields["alchemy-planet"])
        self.assertIn("Inner Edge", fields["calidus-bellicos-stargate-calidus"])
        self.assertIn("Paracelsin", fields["asteroid-belt-outer-edge"])
        self.assertNotIn("deeper Bellicos stargate",
                         " ".join(fields.values()))


if __name__ == "__main__":
    unittest.main()
