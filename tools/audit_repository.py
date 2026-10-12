#!/usr/bin/env python3
"""Read-only repository checks. No third-party packages or GitHub Actions required."""
from __future__ import annotations
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []
WARNINGS: list[str] = []

def error(message: str) -> None:
    ERRORS.append(message)

def warning(message: str) -> None:
    WARNINGS.append(message)

def main() -> int:
    info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
    dependencies = info.get("dependencies", [])
    for retired in ("panglia_planet", "shchierbin"):
        if f"! {retired}" not in dependencies:
            error(f"info.json: missing curated-roster exclusion for {retired}")
        if any(re.match(r"^[?~]?\s*" + re.escape(retired) + r"(?:\s|$)", dep) for dep in dependencies):
            error(f"info.json: retired planet {retired} remains a positive dependency")
    version = info.get("version")
    if info.get("name") != "razi-protocol":
        error("info.json: unexpected mod name")
    if info.get("factorio_version") != "2.1":
        error("info.json: unexpected Factorio version")
    changelog = (ROOT / "changelog.txt").read_text(encoding="utf-8")
    if not re.search(r"^Version:\s*" + re.escape(str(version)) + r"$", changelog, re.M):
        error(f"changelog.txt: missing version {version} release heading")
    entrypoints = ("control.lua", "data.lua", "data-updates.lua",
                   "data-final-fixes.lua", "settings.lua", "settings-final-fixes.lua")
    for path in entrypoints:
        if not (ROOT / path).is_file():
            error(f"missing Factorio entry point: {path}")

    local_modules = {p.relative_to(ROOT).with_suffix("").as_posix().replace("/", ".")
                     for p in ROOT.rglob("*.lua")}
    referenced_modules = set()
    lua_files = list(ROOT.rglob("*.lua"))
    require_re = re.compile(r"\brequire\s*(?:\(\s*)?['\"]([^'\"]+)['\"]")
    asset_re = re.compile(r"__razi-protocol__/([^'\"]+)")
    for path in lua_files:
        content = path.read_text(encoding="utf-8")
        for module in require_re.findall(content):
            name = module.replace("/", ".")
            if name.startswith(("scripts.", "prototypes.")) and name not in local_modules:
                error(f"{path.relative_to(ROOT)}: missing local require {module}")
            referenced_modules.add(name)
        for asset in asset_re.findall(content):
            if not (ROOT / asset).is_file():
                error(f"{path.relative_to(ROOT)}: missing asset {asset}")
    ignored_roots = {"control", "data", "data-updates", "data-final-fixes",
                     "settings", "settings-final-fixes", "util"}
    for module in sorted(local_modules - referenced_modules - ignored_roots):
        warning(f"Lua module has no direct require: {module}")

    story_path = ROOT / "scripts/chronicle/story.lua"
    if not story_path.is_file():
        error("Chronicle story missing")
    else:
        story = story_path.read_text(encoding="utf-8")
        for retired in ("panglia_planet_discovery_panglia", "planet-discovery-shchierbin"):
            if retired in story:
                error(f"Chronicle still contains retired planet objective: {retired}")
        keys = re.findall(r"\{tech\s*=\s*['\"]([^'\"]+)['\"]", story)
        keys += re.findall(r"\{id\s*=\s*['\"]([^'\"]+)['\"]", story)
        duplicate = sorted({key for key in keys if keys.count(key) > 1})
        if duplicate:
            error("duplicate Chronicle identifiers: " + ", ".join(duplicate))
        print(f"Chronicle: {len(keys)} quest identifiers")
    for loc in ("en", "ru"):
        for name in ("names.cfg", "settings.cfg", "compat.cfg"):
            if not (ROOT / "locale" / loc / name).is_file():
                warning(f"missing locale: {loc}/{name}")

    action = ROOT / ".github/workflows/check.yml"
    if action.is_file():
        workflow = action.read_text(encoding="utf-8")
        if "workflow_dispatch:" not in workflow:
            error("GitHub workflow is not manually dispatchable")
        if re.search(r"^\s{2}(push|pull_request):", workflow, re.M):
            error("GitHub Actions automatic trigger detected")
    luac = shutil.which("luac")
    if luac:
        for path in lua_files:
            completed = subprocess.run([luac, "-p", str(path)], capture_output=True, text=True)
            if completed.returncode:
                error(f"Lua syntax: {path.relative_to(ROOT)}: {completed.stderr.strip()}")
        print(f"Lua parser: checked {len(lua_files)} files")
    else:
        print("Lua parser: not installed (optional; use luac -p for full syntax checks)")
    print(f"Audit: {len(lua_files)} Lua files, {len(ERRORS)} errors, {len(WARNINGS)} warnings")
    for message in ERRORS:
        print("ERROR:", message)
    for message in WARNINGS:
        print("WARN:", message)
    return 1 if ERRORS else 0

if __name__ == "__main__":
    raise SystemExit(main())
