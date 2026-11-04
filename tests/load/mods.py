#!/usr/bin/env python3
"""Mod and game versions for the load check (tests/load/run.sh). Standard library only.

  mods.py versions                          game versions of the stable and experimental headless builds, as a CI matrix
  mods.py resolve --info info.json --game 2.1.24 --out mods.lock [--pool DIR ...]
  mods.py fetch   --lock mods.lock --dir CACHE          download what CACHE lacks (needs the portal account, see below)
  mods.py key     --lock mods.lock                       hash of the resolved versions, for the cache key
  mods.py link    --lock mods.lock --dir CACHE --out MODS --razi-zip FILE|--razi-dir DIR [--extra DIR ...]

resolve follows the dependencies of info.json (required, "~" and "+", recursively; "?" and "!" are off) to the newest
portal release built for the game's major.minor version. With --pool the mods come from zips in those folders instead
of the portal (newest of each name), which needs no account. The lock file lists name, version and sha1 of every mod; a
cache keyed by its hash downloads nothing when no version changed.

fetch reads the account from FACTORIO_USERNAME and FACTORIO_TOKEN (the player token of that account). They never appear
in the output.
"""
import argparse
import concurrent.futures
import glob
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

PORTAL = "https://mods.factorio.com"
RELEASES = "https://factorio.com/api/latest-releases"
BUILTIN = {"base", "space-age", "quality", "elevated-rails", "recycler"}
# a mod name may contain spaces ("Flare Stack"): it ends at the version comparison
DEPENDENCY = re.compile(r"^\s*(!|\?|\(\?\)|~|\+)?\s*(.+?)\s*(?:(<=|>=|<|>|=)\s*([\d.]+)\s*)?$")
ZIP_NAME = re.compile(r"^(.+)_(\d+\.\d+\.\d+)\.zip$")


def version_key(text):
    return tuple(int(part) for part in text.split("."))


def fail(message):
    sys.stderr.write("error: " + message + "\n")
    sys.exit(1)


def get_json(url, tries=4):
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "razi-load-check"}), timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            if attempt == tries - 1:
                fail("%s answered %d" % (url, error.code))
        except (urllib.error.URLError, TimeoutError, ConnectionError, json.JSONDecodeError) as error:
            if attempt == tries - 1:
                fail("cannot read %s: %s" % (url, error))
        time.sleep(2 * (attempt + 1))


def dependencies_of(info):
    for dependency in info.get("dependencies", []):
        match = DEPENDENCY.match(dependency)
        if match:
            yield match.groups()


def game_accepts(dependencies, game):
    """False when a release asks for a newer (or other) base than the game."""
    for prefix, name, operator, wanted in dependencies:
        if name != "base" or prefix in ("?", "(?)", "!") or not operator:
            continue
        have, want = version_key(game), version_key(wanted)
        want = want + (0,) * (3 - len(want))
        if (operator == ">=" and have < want) or (operator == ">" and have <= want) or (operator == "=" and have[:len(want)] != want):
            return False
    return True


def cmd_versions(args):
    data = get_json(RELEASES)
    builds = {}
    for channel in ("stable", "experimental"):
        version = data.get(channel, {}).get("headless")
        if not version:
            fail("no headless build for %s in %s" % (channel, RELEASES))
        builds.setdefault(version, []).append(channel)
    include = [{"version": version, "channels": " and ".join(channels)} for version, channels in sorted(builds.items())]
    print("matrix=" + json.dumps({"include": include}, separators=(",", ":")))
    return 0


def zip_info(path):
    with zipfile.ZipFile(path) as archive:
        name = next(entry for entry in archive.namelist() if entry.count("/") == 1 and entry.endswith("/info.json"))
        return json.loads(archive.read(name))


def sha1_of(path):
    digest = hashlib.sha1()
    with open(path, "rb") as file:
        for block in iter(lambda: file.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


class Portal:
    def __init__(self, game):
        self.game = game
        self.minor = ".".join(game.split(".")[:2])
        self.cache = {}

    def newest(self, name):
        if name not in self.cache:
            data = get_json("%s/api/mods/%s/full" % (PORTAL, urllib.parse.quote(name)))
            best = None
            for release in (data or {}).get("releases", []):
                info = release.get("info_json", {})
                if info.get("factorio_version") != self.minor or not game_accepts(list(dependencies_of(info)), self.game):
                    continue
                if best is None or version_key(release["version"]) > version_key(best["version"]):
                    best = release
            self.cache[name] = None if best is None else {
                "name": name, "version": best["version"], "file_name": best["file_name"], "sha1": best["sha1"],
                "download_url": best["download_url"], "dependencies": best.get("info_json", {}).get("dependencies", []),
            }
        return self.cache[name]


class Pool:
    def __init__(self, folders):
        self.mods = {}
        for folder in folders:
            for path in glob.glob(os.path.join(folder, "*.zip")):
                match = None if os.path.islink(path) else ZIP_NAME.match(os.path.basename(path))
                if not match:
                    continue
                name, version = match.groups()
                if name not in self.mods or version_key(version) > version_key(self.mods[name]["version"]):
                    self.mods[name] = {"name": name, "version": version, "file_name": os.path.basename(path), "path": os.path.abspath(path)}

    def newest(self, name):
        mod = self.mods.get(name)
        if mod is not None and "dependencies" not in mod:
            mod["dependencies"] = zip_info(mod["path"]).get("dependencies", [])
        return mod


def cmd_resolve(args):
    with open(args.info) as file:
        info = json.load(file)
    source = Pool(args.pool) if args.pool else Portal(args.game)
    chosen, missing = {}, set()
    wave = {name for prefix, name, _, _ in dependencies_of(info) if prefix not in ("!", "?", "(?)") and name not in BUILTIN}
    while wave:
        # one wave at a time so the portal can be asked in parallel
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            found = dict(zip(sorted(wave), pool.map(source.newest, sorted(wave))))
        wave = set()
        for name, release in found.items():
            if release is None:
                missing.add(name)
                continue
            chosen[name] = release
            for prefix, dependency, _, _ in dependencies_of({"dependencies": release["dependencies"]}):
                if prefix not in ("!", "?", "(?)") and dependency not in BUILTIN and dependency not in chosen and dependency not in missing:
                    wave.add(dependency)
    if missing:
        fail("no release for game %s of: %s" % (args.game, ", ".join(sorted(missing))))
    mods = [{key: value for key, value in chosen[name].items() if key != "dependencies"} for name in sorted(chosen)]
    with open(args.out, "w") as file:
        json.dump({"game": args.game, "mods": mods}, file, indent=1)
        file.write("\n")
    print("%d mods for Factorio %s" % (len(mods), args.game))
    return 0


def read_lock(path):
    with open(path) as file:
        return json.load(file)


def download(entry, target, username, token):
    query = urllib.parse.urlencode({"username": username, "token": token})
    url = PORTAL + entry["download_url"] + "?" + query
    last = "unknown"
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "razi-load-check"}), timeout=120) as response:
                with open(target + ".part", "wb") as file:
                    while True:
                        block = response.read(1 << 20)
                        if not block:
                            break
                        file.write(block)
            if entry.get("sha1") and sha1_of(target + ".part") != entry["sha1"]:
                last = "sha1 does not match"
                continue
            os.replace(target + ".part", target)
            return None
        except urllib.error.HTTPError as error:
            last = "the portal answered %d" % error.code
            if error.code in (401, 403):
                break  # the account or token is wrong: retrying does not help
        except (urllib.error.URLError, TimeoutError, ConnectionError) as error:
            last = type(error).__name__
        time.sleep(3 * (attempt + 1))
    if os.path.exists(target + ".part"):
        os.remove(target + ".part")
    return last


def cmd_fetch(args):
    lock = read_lock(args.lock)
    os.makedirs(args.dir, exist_ok=True)
    wanted = {entry["file_name"] for entry in lock["mods"]}
    for path in glob.glob(os.path.join(args.dir, "*")):
        if os.path.basename(path) not in wanted:
            os.remove(path)  # a version that is not in use any more: keeps the cache from growing
    todo = [entry for entry in lock["mods"] if not os.path.exists(os.path.join(args.dir, entry["file_name"]))]
    print("%d of %d mods in the cache, %d to download" % (len(lock["mods"]) - len(todo), len(lock["mods"]), len(todo)))
    if not todo:
        return 0
    username, token = os.environ.get("FACTORIO_USERNAME", ""), os.environ.get("FACTORIO_TOKEN", "")
    if not username:
        fail("FACTORIO_USERNAME is empty. Set the repository variable FACTORIO_USERNAME to the name of the Factorio account "
             "whose player token is in the secret FACTORIO_PLAYER_TOKEN (the service-username next to the token in "
             "player-data.json).")
    if not token:
        fail("FACTORIO_TOKEN is empty (the repository secret FACTORIO_PLAYER_TOKEN; a pull request from a fork gets no secrets)")
    # a cheap request that only needs a valid account and token: a wrong pair fails here with an explanation, not in 183 downloads
    try:
        urllib.request.urlopen(urllib.request.Request(PORTAL + "/api/bookmarks?" + urllib.parse.urlencode({"username": username, "token": token}),
                                                      headers={"User-Agent": "razi-load-check"}), timeout=60).close()
    except urllib.error.HTTPError as error:
        if error.code in (401, 403):
            fail("the mod portal does not accept FACTORIO_USERNAME with FACTORIO_TOKEN (answer %d). The username must be the name "
                 "of the Factorio account the player token belongs to (service-username beside service-token in player-data.json); "
                 "the token must be the player token, not the portal API key used for releases." % error.code)
        fail("the mod portal answered %d to the account check" % error.code)
    except (urllib.error.URLError, TimeoutError, ConnectionError) as error:
        fail("cannot reach the mod portal: " + type(error).__name__)
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(lambda entry: download(entry, os.path.join(args.dir, entry["file_name"]), username, token), todo))
    failed = [(entry["name"], reason) for entry, reason in zip(todo, results) if reason]
    for name, reason in failed:
        sys.stderr.write("error: %s: %s\n" % (name, reason))
    if failed:
        if any("401" in reason or "403" in reason for _, reason in failed):
            sys.stderr.write("The portal refused the account. FACTORIO_USERNAME must be the account whose token this is, "
                             "and the token must be that account's player token.\n")
        return 1
    print("downloaded %d mods, %.0f MB in the cache" % (len(todo), sum(os.path.getsize(os.path.join(args.dir, e["file_name"])) for e in lock["mods"]) / 1e6))
    return 0


def cmd_key(args):
    # the same mods give the same key whatever the game version they were resolved for
    lines = ["%s %s %s" % (entry["name"], entry["version"], entry.get("sha1", "")) for entry in read_lock(args.lock)["mods"]]
    print(hashlib.sha256("\n".join(sorted(lines)).encode()).hexdigest()[:20])
    return 0


def cmd_link(args):
    lock = read_lock(args.lock)
    os.makedirs(args.out, exist_ok=True)
    for path in glob.glob(os.path.join(args.out, "*")):
        if os.path.islink(path) or os.path.isfile(path):
            os.remove(path)
    names = []
    for entry in lock["mods"]:
        source = entry.get("path") or os.path.join(args.dir, entry["file_name"])
        if not os.path.exists(source):
            fail("%s is missing; run fetch first" % source)
        os.symlink(os.path.abspath(source), os.path.join(args.out, entry["file_name"]))
        names.append(entry["name"])
    if args.razi_zip:
        os.symlink(os.path.abspath(args.razi_zip), os.path.join(args.out, os.path.basename(args.razi_zip)))
    else:
        os.symlink(os.path.abspath(args.razi_dir), os.path.join(args.out, "razi-protocol"))
    for extra in args.extra or []:
        with open(os.path.join(extra, "info.json")) as file:
            extra_name = json.load(file)["name"]
        os.symlink(os.path.abspath(extra), os.path.join(args.out, extra_name))
        names.append(extra_name)
    mods = [{"name": name, "enabled": True} for name in ["base", "space-age", "quality", "elevated-rails", "recycler", "razi-protocol"] + sorted(names)]
    with open(os.path.join(args.out, "mod-list.json"), "w") as file:
        json.dump({"mods": mods}, file, indent=1)
    print("mod-list.json: razi-protocol and %d mods" % len(names))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("versions").set_defaults(run=cmd_versions)
    resolve = sub.add_parser("resolve")
    resolve.add_argument("--info", required=True)
    resolve.add_argument("--game", required=True)
    resolve.add_argument("--out", required=True)
    resolve.add_argument("--pool", action="append")
    resolve.set_defaults(run=cmd_resolve)
    fetch = sub.add_parser("fetch")
    fetch.add_argument("--lock", required=True)
    fetch.add_argument("--dir", required=True)
    fetch.set_defaults(run=cmd_fetch)
    key = sub.add_parser("key")
    key.add_argument("--lock", required=True)
    key.set_defaults(run=cmd_key)
    link = sub.add_parser("link")
    link.add_argument("--lock", required=True)
    link.add_argument("--dir")
    link.add_argument("--out", required=True)
    link.add_argument("--razi-zip")
    link.add_argument("--razi-dir")
    link.add_argument("--extra", action="append")
    link.set_defaults(run=cmd_link)
    args = parser.parse_args()
    sys.exit(args.run(args))


if __name__ == "__main__":
    main()
