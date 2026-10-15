#!/usr/bin/env python3
"""Fix Rabbasca's nil lava textures crash before Factorio can load the mod."""
import argparse
import os
import re
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

OLD = 'lava_effect.water.textures[2].filename = "__rabbasca-assets__/graphics/recolor/textures/lava.png"'
NEW = (
    'if lava_effect.water and type(lava_effect.water.textures) == "table"\n'
    '    and type(lava_effect.water.textures[2]) == "table" then\n'
    '  ' + OLD + '\nend'
)
MARK = 'if lava_effect.water and type(lava_effect.water.textures) == "table"'


def patch(text):
    if MARK in text:
        return text, False
    if text.count(OLD) != 1:
        raise ValueError("Unknown Rabbasca tiles.lua: exact crash line not found")
    endline = "\r\n" if "\r\n" in text else "\n"
    return text.replace(OLD, NEW.replace("\n", endline)), True


def backup(path):
    saved = path.with_name(path.name + ".razi-backup")
    if not saved.exists():
        shutil.copy2(path, saved)
    return saved


def fix(path):
    path = path.expanduser().resolve()
    if path.is_dir():
        file = path / "prototypes" / "tiles.lua"
        manifest = path / "info.json"
        if not manifest.is_file() or not re.search(
            r'"name"\s*:\s*"planet-rabbasca"', manifest.read_text(encoding="utf-8")
        ):
            raise ValueError("Not a Rabbasca source folder")
        text, modified = patch(file.read_text(encoding="utf-8"))
        if not modified:
            return False, None
        saved = backup(file)
        file.write_text(text, encoding="utf-8")
        return True, saved

    if not zipfile.is_zipfile(path):
        raise ValueError("Rabbasca ZIP not found or invalid: " + str(path))
    temp = None
    try:
        with zipfile.ZipFile(path) as archive:
            names = archive.infolist()
            tiles = [i for i in names if i.filename.endswith("/prototypes/tiles.lua")]
            info = [i for i in names if i.filename.endswith("/info.json")]
            if len(tiles) != 1 or not info or not re.search(
                r'"name"\s*:\s*"planet-rabbasca"',
                archive.read(info[0]).decode("utf-8")
            ):
                raise ValueError("Archive is not a uniquely identified Rabbasca mod")
            text, modified = patch(archive.read(tiles[0]).decode("utf-8"))
            if not modified:
                return False, None
            handle, name = tempfile.mkstemp(
                prefix=".razi-rabbasca-", suffix=".zip", dir=path.parent
            )
            os.close(handle)
            temp = Path(name)
            with zipfile.ZipFile(temp, "w", allowZip64=True) as output:
                output.comment = archive.comment
                for item in names:
                    content = (
                        text.encode("utf-8") if item.filename == tiles[0].filename
                        else archive.read(item)
                    )
                    output.writestr(item, content)
        # Close original ZIP before atomic replacement (important on Windows).
        with zipfile.ZipFile(temp) as verified:
            if verified.testzip() is not None:
                raise ValueError("Repacked archive failed ZIP integrity check")
        saved = backup(path)
        os.replace(temp, path)
        return True, saved
    finally:
        if temp is not None and temp.exists():
            temp.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mod", nargs="?", type=Path)
    parser.add_argument("--mods-dir", type=Path)
    args = parser.parse_args()
    if args.mod:
        path = args.mod
    else:
        if args.mods_dir:
            root = args.mods_dir
        elif sys.platform == "win32":
            root = Path(os.environ.get("APPDATA", Path.home())) / "Factorio" / "mods"
        elif sys.platform == "darwin":
            root = Path.home() / "Library/Application Support/factorio/mods"
        else:
            root = Path.home() / ".factorio/mods"
        mods = list(root.glob("planet-rabbasca_*.zip"))
        mods.extend(p for p in root.glob("planet-rabbasca_*") if p.is_dir())
        if not mods:
            raise FileNotFoundError("No planet-rabbasca mod found in " + str(root))
        def version(candidate):
            m = re.search(r"_(\d+(?:\.\d+)+)", candidate.name)
            return tuple(int(p) for p in m.group(1).split(".")) if m else (0,)
        path = max(mods, key=version)
    modified, saved = fix(path)
    print(("Patched " if modified else "Already fixed: ") + str(path))
    if saved:
        print("Original preserved at: " + str(saved))
    print("Restart Factorio to retry Rabbasca loading.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, zipfile.BadZipFile, UnicodeDecodeError) as err:
        sys.exit("Rabbasca patch aborted without modifying this mod: " + str(err))
