#!/usr/bin/env python3
"""Offline source/locale consistency check, not a loaded Factorio graph check."""
from __future__ import annotations
from pathlib import Path
from collections import Counter
import json
import re

ROOT=Path(__file__).resolve().parents[1]
QUEST_FILES=(
    "scripts/razi_journal_data.lua",
    "scripts/razi_journal_expansion.lua",
    "scripts/razi_journal_industry.lua",
    "scripts/razi_journal_frontier.lua",
)
ARCHIVE_FILES=(
    "scripts/razi_journal_records.lua",
    "scripts/razi_journal_corporate.lua",
)

def read(root,path):
    return (root / path).read_text(encoding="utf-8")

def ids_for_quests(root=ROOT):
    return [m.group(1) for path in QUEST_FILES
            for m in re.finditer(r'\{id="([a-z0-9-]+)",chapter="',
                                 read(root,path))]

def archived_entries(root=ROOT):
    return [(m.group(1),m.group(2)) for path in ARCHIVE_FILES
            for m in re.finditer(
                r'\{id="([a-z0-9-]+)",unlock="([a-z0-9-]+)"',
                read(root,path))]

def duplicate_ids(names):
    counts=Counter(names)
    return sorted(key for key,count in counts.items() if count>1)

def inspect(root=ROOT):
    from tools.journal_locale import parse_cfg
    quests=ids_for_quests(root)
    known=set(quests)
    records=archived_entries(root)
    brief_source=read(root,"scripts/razi_planet_briefs.lua")
    brief_ids=re.findall(r'^  ([a-z0-9-]+)="[a-z0-9-]+",?$',brief_source,re.M)
    relation_source=read(root,"scripts/razi_planet_briefs.lua")
    section=re.search(r"local connections=\{(.*?)\n\}",relation_source,re.S)
    links=re.findall(r'^  ([a-z0-9-]+)=\{([^}]*)\},?$',section.group(1),re.M) if section else []
    relation_targets=[]
    repeated=[]
    owners=[]
    for owner,payload in links:
        owners.append(owner)
        targets=re.findall(r'"([a-z0-9-]+)"',payload)
        if len(targets)!=len(set(targets)): repeated.append(owner)
        relation_targets.extend(targets)
    translations,locale_errors=parse_cfg(
        read(root,"locale/en/razi_journal_corporate.cfg"),
        "razi_journal_corporate.cfg")
    for name,_ in records:
        if name.startswith("corp-"):
            for section in ("journal-record-title","journal-record-origin",
                            "journal-record-body"):
                if (section,name) not in translations:
                    locale_errors.append(f"missing [{section}] {name}")
    for name in brief_ids:
        if ("razi-industries-brief",name) not in translations:
            locale_errors.append(f"missing [razi-industries-brief] {name}")
    return {
        "quest_count":len(quests),
        "record_count":len(records),
        "brief_count":len(brief_ids),
        "duplicate_quest_ids":duplicate_ids(quests),
        "duplicate_record_ids":duplicate_ids([name for name,_ in records]),
        "record_unlocks_without_quests":
            sorted({unlock for _,unlock in records if unlock not in known}),
        "briefs_without_quests":sorted(set(brief_ids)-known),
        "related_quest_targets_missing":sorted(set(relation_targets)-known),
        "duplicate_related_targets":sorted(repeated),
        "links_without_briefs":sorted(set(owners)-set(brief_ids)),
        "locale_errors":locale_errors,
    }

if __name__=="__main__":
    report=inspect()
    print(json.dumps(report,indent=2))
    raise SystemExit(any(report[key] for key in (
        "duplicate_quest_ids","duplicate_record_ids",
        "record_unlocks_without_quests","briefs_without_quests",
        "related_quest_targets_missing","duplicate_related_targets",
        "links_without_briefs","locale_errors"
    )))
