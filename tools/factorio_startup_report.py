#!/usr/bin/env python3
"""Compare logged Factorio startup phase durations without changing a save.

The input is the original factorio-current.log / factorio-previous.log.
Only explicit startup markers are measured; missing or reordered markers
produce missing results, not fictitious speedup numbers.
"""
import argparse
import json
import re
from pathlib import Path

TIMESTAMP = re.compile(r"^\s*(\d+(?:\.\d+)?)\s+")
PHASES = (
    ("mod_settings", "Loading mod settings"),
    ("mod_prototypes", "Loading mod prototypes"),
    ("build_prototypes", "Building prototypes"),
    ("sprites", "Loading sprites"),
    ("sounds", "Loading sounds"),
)
FINISH = ("Factorio initialised", "Factorio initialized")
LABELS = dict(PHASES)

def parse_log(text):
    markers = {}
    for line in text.splitlines():
        match = TIMESTAMP.match(line)
        if not match:
            continue
        timestamp = float(match.group(1))
        if not (0 <= timestamp < 1_000_000):
            continue
        for key, phrase in PHASES:
            if key not in markers and phrase.lower() in line.lower():
                markers[key] = timestamp
        if "finish" not in markers and any(
            phrase.lower() in line.lower() for phrase in FINISH
        ):
            markers["finish"] = timestamp

    durations = {}
    # A stage ends at the next *observed* milestone in the expected order.
    # Never report a phase if a missing intermediate marker makes its
    # boundaries ambiguous.
    ordered = [key for key, _ in PHASES] + ["finish"]
    for index, key in enumerate(ordered[:-1]):
        following = ordered[index + 1]
        if key in markers and following in markers and (
            markers[following] >= markers[key]
        ):
            durations[key] = round(markers[following] - markers[key], 3)

    first = ordered[0]
    startup_window = (
        round(markers["finish"] - markers[first], 3)
        if first in markers and "finish" in markers
        and markers["finish"] >= markers[first] else None
    )
    return {
        "markers": markers,
        "durations": durations,
        "observed_startup_window": startup_window,
        "missing": [key for key in ordered if key not in markers],
    }

def compare(before, after):
    keys = [key for key, _ in PHASES]
    phases = {}
    for key in keys:
        old = before["durations"].get(key)
        new = after["durations"].get(key)
        phases[key] = {
            "before_s": old, "after_s": new,
            "delta_s": round(new - old, 3)
            if old is not None and new is not None else None,
        }
    old = before["observed_startup_window"]
    new = after["observed_startup_window"]
    return {
        "phases": phases,
        "total": {
            "before_s": old, "after_s": new,
            "delta_s": round(new - old, 3)
            if old is not None and new is not None else None,
        },
        "caveats": [
            "Negative delta means faster on the supplied logs, not a proven mod-level cause.",
            "Only phases with adjacent explicit markers are measured.",
            "Use identical Factorio version, mods, startup settings and cache state.",
            "Compare more than one cold and warm run before attributing speedups.",
        ],
    }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", type=Path, required=True)
    parser.add_argument("--after", type=Path, required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    before = parse_log(args.before.read_text(encoding="utf-8", errors="replace"))
    after = parse_log(args.after.read_text(encoding="utf-8", errors="replace"))
    report = compare(before, after)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("Factorio startup phase comparison (seconds; negative = faster)")
        for key, _ in PHASES:
            values = report["phases"][key]
            delta = values["delta_s"]
            print(f"  {key:<19} {delta:+.3f}" if delta is not None
                  else f"  {key:<19} unavailable")
        delta = report["total"]["delta_s"]
        print(f"  {'observed startup':<19} {delta:+.3f}" if delta is not None
              else "  observed startup    unavailable")
        print("This is not a causal benchmark. Match cache and mod versions.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
