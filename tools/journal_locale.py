"""Authoring and validation utilities for the split Factorio Expedition Journal locale.

Run: python tools/journal_locale.py
All Factorio section/key IDs are preserved across separate .cfg files.
"""
from __future__ import annotations

from collections import Counter
from pathlib import Path
import re
import sys

FILES = (
    "razi_journal_interface.cfg",
    "razi_journal_chapters.cfg",
    "razi_journal_titles.cfg",
    "razi_journal_stories.cfg",
    "razi_journal_field_notes.cfg",
    "razi_journal_transmissions.cfg",
    "razi_journal_corporate.cfg",
)
ROOT = Path(__file__).resolve().parents[1]


def load_journal_locale(root: Path = ROOT, language: str = "en") -> str:
    """Concatenate all journal locale sections for tests and editing tools."""
    folder = root / "locale" / language
    return "\n".join((folder / name).read_text(encoding="utf-8") for name in FILES)


def parse_cfg(source: str, source_name: str):
    section = None
    result = {}
    errors = []
    for number, raw in enumerate(source.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith(("#", ";")):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if "=" not in raw or not section:
            errors.append(f"{source_name}:{number}: invalid entry or missing section")
            continue
        key, value = raw.split("=", 1)
        key = key.strip()
        identifier = (section, key)
        if identifier in result:
            errors.append(f"{source_name}:{number}: duplicate [{section}] {key}")
        result[identifier] = value
    return result, errors


def placeholder_tokens(value: str):
    return Counter(re.findall(r"__(?:\d+)__", value))


def validate(root: Path = ROOT):
    english = {}
    problems = []
    en = root / "locale" / "en"
    for name in FILES:
        path = en / name
        if not path.is_file():
            problems.append(f"missing English journal file: {path}")
            continue
        found, errors = parse_cfg(path.read_text(encoding="utf-8"), str(path))
        problems.extend(errors)
        for identifier, value in found.items():
            if identifier in english:
                problems.append(f"duplicate English locale key across files: {identifier}")
            english[identifier] = value

    languages = root / "locale"
    for folder in sorted(languages.iterdir()):
        if not folder.is_dir() or folder.name == "en":
            continue
        translated = {}
        for cfg in folder.glob("*.cfg"):
            parsed, errors = parse_cfg(cfg.read_text(encoding="utf-8"), str(cfg))
            problems.extend(errors)
            for identifier, value in parsed.items():
                if identifier in translated:
                    problems.append(f"duplicate translated key in {folder.name}: {identifier}")
                translated[identifier] = value
        for identifier, translation in translated.items():
            if identifier not in english:
                continue  # Other mods and older translation keys may differ.
            original = placeholder_tokens(english[identifier])
            actual = placeholder_tokens(translation)
            if original != actual:
                problems.append(
                    f"{folder.name} [{identifier[0]}] {identifier[1]}: "
                    f"placeholder mismatch {dict(original)} vs {dict(actual)}"
                )
    return len(english), problems


if __name__ == "__main__":
    count, problems = validate()
    print(f"Expedition Journal: {count} English section/key entries checked")
    for item in problems:
        print("ERROR:", item)
    sys.exit(bool(problems))
