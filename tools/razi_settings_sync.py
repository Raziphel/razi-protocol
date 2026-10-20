#!/usr/bin/env python3
"""Sync *real* Factorio mod-settings.dat values to Razi's startup difficulty.

Run only while Factorio is CLOSED. No mod Lua can perform this operation:
startup settings are already frozen when other mod code can read the preset.
Stdlib only; --apply is opt-in and creates a backup + validates round trips.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import struct
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any
from zipfile import ZipFile, BadZipFile

MANIFEST = Path(__file__).with_name("razi_difficulty_setting_manifest.json")
MAX_FILE = 32 * 1024 * 1024
MAX_ITEMS = 100000
MAX_DEPTH = 32


@dataclass
class Node:
    kind: int
    flag: int
    value: Any


class Codec:
    """Factorio 2.1 PropertyTree. Unknown flags/types fail safely."""

    def __init__(self, payload: bytes = b""):
        self.raw = payload
        self.at = 0

    def get(self, n: int) -> bytes:
        if n < 0 or self.at + n > len(self.raw):
            raise ValueError("Unexpected end of Factorio settings file")
        b = self.raw[self.at : self.at + n]
        self.at += n
        return b

    def number(self, fmt: str) -> Any:
        return struct.unpack("<" + fmt, self.get(struct.calcsize("<" + fmt)))[0]

    def string(self) -> str | None:
        is_null = self.number("B")
        if is_null not in (0, 1):
            raise ValueError("Unknown string marker")
        if is_null:
            return None
        n = self.number("B")
        if n == 255:
            n = self.number("I")
        if n > MAX_FILE:
            raise ValueError("Oversized string")
        return self.get(n).decode("utf-8")

    def node(self, depth: int = 0) -> Node:
        if depth > MAX_DEPTH:
            raise ValueError("PropertyTree nesting too deep")
        kind, flag = self.number("B"), self.number("B")
        if flag not in (0, 1):
            raise ValueError("Unsupported PropertyTree flags")
        if kind == 0:
            value = None
        elif kind == 1:
            value = bool(self.number("B"))
        elif kind == 2:
            value = self.number("d")
        elif kind == 3:
            value = self.string()
        elif kind in (4, 5):
            n = self.number("I")
            if n > MAX_ITEMS:
                raise ValueError("Too many property-tree elements")
            result = {} if kind == 5 else []
            for _ in range(n):
                key = self.string()
                child = self.node(depth + 1)
                if kind == 5:
                    if key is None or key in result:
                        raise ValueError("Invalid or duplicate PropertyTree key")
                    result[key] = child
                else:
                    if key not in (None, ""):
                        raise ValueError("List child has a non-empty key")
                    result.append(child)
            value = result
        elif kind == 6:
            value = self.number("q")
        elif kind == 7:
            value = self.number("Q")
        else:
            raise ValueError("Unsupported PropertyTree kind " + str(kind))
        return Node(kind, flag, value)

    @staticmethod
    def out_string(s: str | None) -> bytes:
        if s is None:
            return b"\\x01"
        raw = s.encode("utf-8")
        length = len(raw)
        return (b"\\x00" + (bytes((length,)) if length < 255 else
                b"\\xff" + struct.pack("<I", length)) + raw)

    @classmethod
    def out_node(cls, n: Node, depth: int = 0) -> bytes:
        if depth > MAX_DEPTH or n.flag not in (0, 1):
            raise ValueError("Invalid PropertyTree node")
        data = bytearray((n.kind, n.flag))
        if n.kind == 0:
            pass
        elif n.kind == 1:
            data += bytes((1 if n.value else 0,))
        elif n.kind == 2:
            data += struct.pack("<d", n.value)
        elif n.kind == 3:
            data += cls.out_string(n.value)
        elif n.kind in (4, 5):
            value = n.value
            data += struct.pack("<I", len(value))
            iterator = value.items() if n.kind == 5 else ((None, v) for v in value)
            for key, child in iterator:
                data += cls.out_string(key)
                data += cls.out_node(child, depth + 1)
        elif n.kind in (6, 7):
            data += struct.pack("<q" if n.kind == 6 else "<Q", n.value)
        else:
            raise ValueError("Unknown PropertyTree kind")
        return bytes(data)


def decode(raw: bytes) -> tuple[bytes, Node]:
    if not 9 < len(raw) <= MAX_FILE:
        raise ValueError("Not a plausible mod-settings.dat size")
    version = struct.unpack("<4H", raw[:8])
    if version[0] not in (2,) or raw[8] != 0:
        raise ValueError("Only standard Factorio 2.x settings are supported")
    codec = Codec(raw)
    header = codec.get(9)
    root = codec.node()
    if root.kind != 5 or codec.at != len(raw):
        raise ValueError("Settings require one complete dictionary PropertyTree")
    if Codec.out_node(root) != raw[9:]:
        raise ValueError("PropertyTree is not byte-for-byte round-trippable")
    for section in ("startup", "runtime-global", "runtime-per-user"):
        if section not in root.value or root.value[section].kind != 5:
            raise ValueError("Missing settings dictionary " + section)
    return header, root


def encode(header: bytes, root: Node) -> bytes:
    return header + Codec.out_node(root)


def setting_value(section: Node, name: str) -> Node | None:
    entry = section.value.get(name)
    if entry is None:
        return None
    if entry.kind != 5 or "value" not in entry.value:
        raise ValueError("Malformed setting: " + name)
    return entry.value["value"]


def allowed_type(kind: str, value: Any) -> bool:
    if kind == "bool":
        return type(value) is bool
    if kind == "string":
        return isinstance(value, str)
    if kind == "int":
        return type(value) is int
    if kind == "double":
        return type(value) in (int, float)
    return False


def with_value(previous: Node | None, value: Any, kind: str) -> Node:
    if not allowed_type(kind, value):
        raise ValueError("Manifest value has an incorrect type")
    if previous:
        if kind == "bool" and previous.kind != 1:
            raise ValueError("Stored bool setting has the wrong data type")
        if kind == "string" and previous.kind != 3:
            raise ValueError("Stored string setting has the wrong data type")
        if kind in ("int", "double") and previous.kind not in (2, 6, 7):
            raise ValueError("Stored numeric setting has the wrong data type")
        target_type = previous.kind
        if kind == "double" and target_type in (6, 7) and value != int(value):
            target_type = 2
        return Node(target_type, previous.flag, float(value) if target_type == 2 else value)
    type_id = {"bool": 1, "string": 3, "int": 2, "double": 2}[kind]
    return Node(type_id, 0, float(value) if type_id == 2 else value)


def enabled_mods(mods_dir: Path) -> set[str]:
    file = mods_dir / "mod-list.json"
    if not file.is_file():
        raise ValueError("mod-list.json not found alongside mod-settings.dat")
    manifest = json.loads(file.read_text(encoding="utf-8"))
    return {entry["name"] for entry in manifest["mods"] if entry.get("enabled")}


def source_has_setting(mods_dir: Path, mod: str, setting: str) -> bool:
    """Verify the installed mod's real settings.lua defines the exact ID.

    Never execute installed mod code. Do not invent or edit absent settings.
    """
    options = sorted(mods_dir.glob(mod + "_*"), reverse=True)
    quoted = ('"' + setting + '"', "'" + setting + "'")
    for path in options:
        try:
            if path.is_dir():
                source = path.joinpath("settings.lua")
                if not source.is_file():
                    continue
                content = source.read_text(encoding="utf-8")
            elif path.suffix.lower() == ".zip" and path.is_file():
                with ZipFile(path) as archive:
                    candidates = [name for name in archive.namelist()
                                  if name.count("/") == 1 and name.endswith("/settings.lua")]
                    if len(candidates) != 1:
                        continue
                    content = archive.read(candidates[0]).decode("utf-8")
            else:
                continue
        except (OSError, BadZipFile, UnicodeDecodeError, KeyError):
            continue
        if any(q in content for q in quoted):
            return True
    return False


def plan(mods_dir: Path, root: Node, manifest: dict, runtime: bool) -> tuple[list, list]:
    modes = manifest["modes"]
    startup = root.value["startup"]
    selected_node = setting_value(startup, "razi-difficulty-preset")
    mode = selected_node.value if selected_node else "normal"
    if mode == "custom":
        return [], ["Custom difficulty selected; no foreign settings are rewritten"]
    if mode not in modes:
        raise ValueError("Unknown Razi difficulty: " + str(mode))
    installed = enabled_mods(mods_dir)
    if "razi-protocol" not in installed:
        raise ValueError("Razi Protocol is not enabled in mod-list.json")
    changes, skipped = [], []
    for item in manifest["entries"]:
        if item["mod"] not in installed:
            skipped.append(item["name"] + ": source mod disabled")
            continue
        if item["section"] != "startup" and not runtime:
            skipped.append(item["name"] + ": runtime setting (opt in for NEW saves)")
            continue
        if not source_has_setting(mods_dir, item["mod"], item["name"]):
            skipped.append(item["name"] + ": exact setting ID not verified in installed mod")
            continue
        section = root.value[item["section"]]
        old = setting_value(section, item["name"])
        new_value = item["values"][mode]
        if "min" in item and not (item["min"] <= new_value <= item["max"]):
            raise ValueError("Out-of-range value for " + item["name"])
        new = with_value(old, new_value, item["type"])
        if old is not None and old.value == new.value:
            continue
        changes.append((section, item["name"], old, new, item["section"], item["mod"]))
    return changes, skipped


def factorio_running() -> bool:
    """Best-effort guard: don't overwrite an open client's mod-settings.dat."""
    if sys.platform.startswith("linux") and Path("/proc").exists():
        for file in Path("/proc").glob("[0-9]*/comm"):
            try:
                if file.read_text().strip().lower() == "factorio":
                    return True
            except OSError:
                pass
    elif sys.platform == "win32":
        import subprocess
        try:
            output = subprocess.run(["tasklist", "/FI", "IMAGENAME eq factorio.exe"],
                                    capture_output=True, text=True, timeout=5, check=False)
            return "factorio.exe" in output.stdout.lower()
        except (OSError, subprocess.TimeoutExpired):
            return True
    return False


def write_atomic(path: Path, initial: bytes, output: bytes) -> Path:
    if path.read_bytes() != initial:
        raise RuntimeError("Settings file changed during synchronization; retry")
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    backup = path.with_name(path.name + ".razi-backup-" + timestamp)
    if backup.exists():
        raise FileExistsError("Backup already exists; don't overwrite " + str(backup))
    shutil.copy2(path, backup)
    fd, temp_name = tempfile.mkstemp(prefix=".razi-settings-", dir=str(path.parent))
    temp = Path(temp_name)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(output)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp, stat.S_IMODE(path.stat().st_mode))
        if path.read_bytes() != initial:
            raise RuntimeError("Settings file changed; original and backup preserved")
        os.replace(temp, path)
    finally:
        temp.unlink(missing_ok=True)
    return backup


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mods-dir", type=Path, required=True,
                        help="Folder containing mod-settings.dat, mod-list.json and installed mods")
    parser.add_argument("--apply", action="store_true",
                        help="Write actual mod-settings.dat values; otherwise dry run")
    parser.add_argument("--include-runtime-global", action="store_true",
                        help="Also write default MAP settings for NEW saves; existing saves are unaffected")
    args = parser.parse_args(argv)
    mods_dir = args.mods_dir.expanduser().resolve()
    file = mods_dir / "mod-settings.dat"
    if not file.is_file() or file.is_symlink():
        parser.error("No regular mod-settings.dat file at " + str(file))
    try:
        source = file.read_bytes()
        header, root = decode(source)
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        if manifest.get("schema_version") != 1:
            raise ValueError("Unsupported sync manifest version")
        changes, skipped = plan(mods_dir, root, manifest, args.include_runtime_global)
        mode_node = setting_value(root.value["startup"], "razi-difficulty-preset")
        mode = mode_node.value if mode_node else "normal"
        print("Razi difficulty:", mode, "|", "APPLY" if args.apply else "PREVIEW")
        for section, name, old, new, setting_type, mod in changes:
            before = old.value if old else "(source default)"
            print(" ", mod, "/", setting_type, "/", name, ":", before, "=>", new.value)
        if skipped:
            print("Skipped", len(skipped), "setting(s):")
            for reason in skipped:
                print("  -", reason)
        print("Changes:", len(changes))
        if not changes or not args.apply:
            if changes:
                print("Run again with --apply AFTER closing Factorio to write these values.")
            return 0
        if factorio_running():
            raise RuntimeError("Factorio appears to be running. Close it before applying.")
        for section, name, _old, new, _kind, _mod in changes:
            section.value[name] = Node(5, 0, {"value": new})
        output = encode(header, root)
        hdr, check = decode(output)
        if hdr != header or encode(hdr, check) != output:
            raise RuntimeError("Binary round-trip verification failed")
        backup = write_atomic(file, source, output)
        print("Updated:", file)
        print("Backup:", backup)
        return 0
    except (ValueError, OSError, RuntimeError, KeyError, TypeError, struct.error) as error:
        print("No settings modified:", error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
