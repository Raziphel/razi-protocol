#!/usr/bin/env python3
"""Audit the full, recursively required Factorio Mod Portal dependency graph.

Reads Razi's info.json, fetches compatible 2.1 releases from the public Mod
Portal API, follows hard dependency edges, and reports duplicates and version
pins. No changes are made to info.json and no GitHub Actions are started.

Network use is explicit. Reuse --cache-dir and --offline for reproducibility.
"""
import argparse
import json
import re
import sys
import time
from collections import deque
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
PORTAL = "https://mods.factorio.com/api/mods/"
BUILTINS = {"base", "space-age", "quality", "recycler", "elevated-rails"}
DECLARATION = re.compile(
    r"^\s*(?:(\(\?\)|[+?!~])\s+)?(\S+?)"
    r"(?:\s*(>=|<=|=|>|<)\s*([0-9]+(?:\.[0-9]+)*))?\s*$"
)


def parse(raw):
    match = DECLARATION.fullmatch(raw)
    if not match:
        raise ValueError("Unknown dependency declaration: " + raw)
    prefix, name, operator, version = match.groups()
    kind = {
        None: "required", "+": "recommended", "?": "optional",
        "(?)": "hidden-optional", "~": "load-order-independent",
        "!": "incompatible",
    }[prefix]
    return {"raw": raw, "name": name, "kind": kind,
            "operator": operator, "version": version}


def version_parts(text):
    return tuple(int(part) for part in text.split("."))


def compare_versions(left, right):
    a, b = version_parts(left), version_parts(right)
    size = max(len(a), len(b))
    a += (0,) * (size-len(a))
    b += (0,) * (size-len(b))
    return (a > b) - (a < b)


def matches_version(actual, operator, wanted):
    if not operator:
        return True
    cmp = compare_versions(actual, wanted)
    return {"=": cmp == 0, ">=": cmp >= 0, "<=": cmp <= 0,
            ">": cmp > 0, "<": cmp < 0}[operator]


class Portal:
    def __init__(self, cache_dir, offline=False, pause=0.06):
        self.cache_dir = Path(cache_dir)
        self.offline = offline
        self.pause = pause
        self.memory = {}

    def fetch(self, name):
        if name in self.memory:
            return self.memory[name]
        path = self.cache_dir / (quote(name, safe="") + ".json")
        if path.is_file():
            item = json.loads(path.read_text(encoding="utf-8"))
        elif self.offline:
            raise RuntimeError("Not cached for offline audit: " + name)
        else:
            request = Request(PORTAL + quote(name, safe="") + "/full",
                              headers={"User-Agent": "RaziProtocolDependencyAudit/1.0"})
            try:
                with urlopen(request, timeout=15) as response:
                    item = json.load(response)
            except (HTTPError, URLError, TimeoutError) as exc:
                raise RuntimeError(str(exc)) from exc
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(item, indent=2) + "\n",
                            encoding="utf-8")
            if self.pause:
                time.sleep(self.pause)
        releases = [
            release for release in item.get("releases", [])
            if str(release.get("info_json", {}).get("factorio_version",
                                                  "")).split(".")[:2] == ["2", "1"]
        ]
        if not releases:
            raise RuntimeError("No native Factorio 2.1 release: " + name)
        release = max(releases, key=lambda r: version_parts(r["version"]))
        result = {"name": name, "version": release["version"],
                  "dependencies": [
                      parse(d) for d in release.get("info_json", {})
                      .get("dependencies", ["base"])
                  ]}
        self.memory[name] = result
        return result


def audit(manifest, portal):
    declarations = [parse(d) for d in manifest["dependencies"]]
    roots = {d["name"]: d for d in declarations if d["kind"] == "required"}
    secondary = [d for d in declarations
                 if d["kind"] in ("recommended", "optional", "hidden-optional",
                                  "load-order-independent")]
    excluded = {d["name"] for d in declarations if d["kind"] == "incompatible"}
    graph, missing, violations = {}, [], []
    queue = deque(sorted(name for name in roots if name not in BUILTINS))
    attempts = set()
    while queue:
        name = queue.popleft()
        if name in attempts or name in BUILTINS:
            continue
        attempts.add(name)
        try:
            record = portal.fetch(name)
        except (RuntimeError, ValueError) as exc:
            missing.append({"mod": name, "error": str(exc)})
            continue
        graph[name] = record
        for edge in record["dependencies"]:
            target = edge["name"]
            if edge["kind"] != "required":
                continue
            if target in excluded:
                violations.append({"mod": name, "dependency": target,
                                   "problem": "Required mod depends on an incompatible mod"})
            if target not in BUILTINS:
                queue.append(target)
    edges = {}
    for source, record in graph.items():
        for edge in record["dependencies"]:
            if edge["kind"] == "required":
                edges.setdefault(source, []).append(edge)
                installed = graph.get(edge["name"])
                if installed and not matches_version(
                        installed["version"], edge["operator"],
                        edge["version"]):
                    violations.append({
                        "mod": source, "dependency": edge["name"],
                        "problem": "Selected 2.1 release fails " + edge["raw"],
                        "selected": installed["version"]
                    })
    for root in roots.values():
        installed = graph.get(root["name"])
        if installed and not matches_version(
                installed["version"], root["operator"], root["version"]):
            violations.append({
                "mod": "razi-protocol", "dependency": root["name"],
                "problem": "Selected 2.1 release fails " + root["raw"],
                "selected": installed["version"]
            })

    def paths_to(target):
        """A source-mod chain independently guaranteeing the target exists."""
        paths = []
        for root in sorted(roots):
            if root == target or root in BUILTINS:
                continue
            work = deque([(root, [root])])
            seen = set()
            while work:
                current, path = work.popleft()
                if current in seen:
                    continue
                seen.add(current)
                for edge in edges.get(current, []):
                    child = edge["name"]
                    if child == target:
                        paths.append({"path": path + [target],
                                      "operator": edge["operator"],
                                      "minimum": edge["version"]})
                    elif child not in seen and child in graph:
                        work.append((child, path + [child]))
        return paths

    redundant, pinned, indirectly_required = [], [], []
    for direct in declarations:
        if direct["name"] in BUILTINS or direct["kind"] == "incompatible":
            continue
        paths = paths_to(direct["name"])
        if not paths:
            continue
        info = {"mod": direct["name"], "declared": direct["raw"],
                "through": paths[:8]}
        if direct["kind"] != "required":
            indirectly_required.append(info)
            continue
        sufficient = [
            p for p in paths
            if (not direct["operator"]) or
            (p["operator"] in (">=", "=")
             and p["minimum"] is not None
             and compare_versions(p["minimum"], direct["version"]) >= 0)
        ]
        if sufficient:
            info["through"] = sufficient[:8]
            redundant.append(info)
        else:
            pinned.append(info)

    return {
        "factorio_version": manifest.get("factorio_version"),
        "declarations": len(declarations),
        "required_direct": len(roots),
        "visited_native_2_1_mods": len(graph),
        "transitive_required_mods": sorted(set(graph)-set(roots)),
        "redundant_direct_requirements": redundant,
        "transitive_with_stronger_direct_version_pins": pinned,
        "recommended_or_optional_already_forced": indirectly_required,
        "missing_or_incompatible_releases": missing,
        "dependency_violations": violations,
        "review_note": (
            "Mod Portal API data is release-specific. Versions, compatibility, "
            "and transitive closure change with upstream updates. This is a "
            "dependency graph audit, not a Factorio engine or save-game test."
        ),
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=ROOT / "info.json")
    parser.add_argument("--cache-dir", type=Path,
                        default=Path.home() / ".cache" / "razi-mod-portal")
    parser.add_argument("--offline", action="store_true",
                        help="Only use cached full Mod Portal API JSON")
    parser.add_argument("--json", type=Path,
                        help="Write detailed JSON findings to this file")
    parser.add_argument("--check", action="store_true",
                        help="Exit nonzero for unresolved mods or broken hard deps")
    args = parser.parse_args(argv)
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    report = audit(manifest, Portal(args.cache_dir, args.offline))
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, indent=2) + "\n",
                             encoding="utf-8")
    for key in ("declarations", "required_direct", "visited_native_2_1_mods"):
        print(key + ": " + str(report[key]))
    for key in ("redundant_direct_requirements",
                "transitive_with_stronger_direct_version_pins",
                "recommended_or_optional_already_forced",
                "missing_or_incompatible_releases", "dependency_violations"):
        print("\n" + key + ": " + str(len(report[key])))
        for record in report[key]:
            print("  " + record.get("mod", "?") + ": " +
                  str(record.get("through", record.get("error",
                                                     record.get("problem")))))
    if args.check and (report["missing_or_incompatible_releases"] or
                       report["dependency_violations"]):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
