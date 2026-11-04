#!/usr/bin/env python3
"""Reads and writes Factorio's mod-settings.dat (the binary property tree) with the standard library only.

  mod_settings.py write <out.dat> [--base <in.dat>] [--game 2.1.24] [name=value ...]
  mod_settings.py dump <in.dat>

`write` sets startup settings. Without --base the file holds only those settings, everything else keeps its default.
With --base the other settings of that file are kept. A value that looks like true/false is a boolean, a number is a
number, anything else is a string.
"""
import json
import struct
import sys

NONE, BOOL, NUMBER, STRING, LIST, DICT, INT64, UINT64 = range(8)


class Reader:
    def __init__(self, data):
        self.data = data
        self.pos = 0

    def take(self, size):
        chunk = self.data[self.pos:self.pos + size]
        if len(chunk) != size:
            raise ValueError("mod-settings.dat ends in the middle of a value")
        self.pos += size
        return chunk

    def u8(self):
        return self.take(1)[0]

    def u32(self):
        return struct.unpack("<I", self.take(4))[0]

    def string(self):
        if self.u8():
            return ""
        size = self.u8()
        if size == 255:
            size = self.u32()
        return self.take(size).decode("utf-8")

    def tree(self):
        kind = self.u8()
        self.u8()  # the "any type" flag, not needed to read the value
        if kind == NONE:
            return (NONE, None)
        if kind == BOOL:
            return (BOOL, bool(self.u8()))
        if kind == NUMBER:
            return (NUMBER, struct.unpack("<d", self.take(8))[0])
        if kind == STRING:
            return (STRING, self.string())
        if kind == INT64:
            return (INT64, struct.unpack("<q", self.take(8))[0])
        if kind == UINT64:
            return (UINT64, struct.unpack("<Q", self.take(8))[0])
        if kind in (LIST, DICT):
            return (kind, [(self.string(), self.tree()) for _ in range(self.u32())])
        raise ValueError("unknown property tree type %d" % kind)


def put_string(value, keep_empty=False):
    raw = value.encode("utf-8")
    if not raw and not keep_empty:
        return b"\x01"
    size = bytes([len(raw)]) if len(raw) < 255 else b"\xff" + struct.pack("<I", len(raw))
    return b"\x00" + size + raw


def put_tree(node):
    kind, value = node
    head = bytes([kind, 0])
    if kind == NONE:
        return head
    if kind == BOOL:
        return head + bytes([1 if value else 0])
    if kind == NUMBER:
        return head + struct.pack("<d", value)
    if kind == STRING:
        return head + put_string(value, keep_empty=True)
    if kind == INT64:
        return head + struct.pack("<q", value)
    if kind == UINT64:
        return head + struct.pack("<Q", value)
    return head + struct.pack("<I", len(value)) + b"".join(put_string(key) + put_tree(child) for key, child in value)


def parse(data):
    reader = Reader(data)
    version = struct.unpack("<4H", reader.take(8))
    reader.u8()
    root = reader.tree()
    if reader.pos != len(data):
        raise ValueError("%d unread bytes at the end of mod-settings.dat" % (len(data) - reader.pos))
    return version, root


def serialize(version, root):
    return struct.pack("<4H", *version) + b"\x00" + put_tree(root)


def scalar(text):
    if text in ("true", "false"):
        return (BOOL, text == "true")
    try:
        return (NUMBER, float(text))
    except ValueError:
        return (STRING, text)


def game_version(text):
    parts = [int(part) for part in text.split(".")][:4]
    return tuple(parts + [0] * (4 - len(parts)))


def set_startup(root, settings):
    sections = dict(root[1])
    for name in ("startup", "runtime-global", "runtime-per-user"):
        sections.setdefault(name, (DICT, []))
    startup = dict(sections["startup"][1])
    for name, value in settings.items():
        startup[name] = (DICT, [("value", value)])
    sections["startup"] = (DICT, list(startup.items()))
    order = ["startup", "runtime-global", "runtime-per-user"]
    return (DICT, [(name, sections[name]) for name in order] + [(k, v) for k, v in sections.items() if k not in order])


def to_json(node):
    kind, value = node
    if kind in (LIST, DICT):
        return {key: to_json(child) for key, child in value}
    return value


def main(argv):
    if len(argv) >= 2 and argv[0] == "dump":
        with open(argv[1], "rb") as file:
            json.dump(to_json(parse(file.read())[1]), sys.stdout, indent=1, sort_keys=True)
        print()
        return 0
    if len(argv) >= 2 and argv[0] == "write":
        out, rest = argv[1], argv[2:]
        base, game, settings = None, "2.1.24", {}
        while rest:
            if rest[0] == "--base":
                base, rest = rest[1], rest[2:]
            elif rest[0] == "--game":
                game, rest = rest[1], rest[2:]
            elif "=" in rest[0]:
                name, _, text = rest[0].partition("=")
                settings[name] = scalar(text)
                rest = rest[1:]
            else:
                sys.exit("unknown argument " + rest[0])
        if base:
            with open(base, "rb") as file:
                version, root = parse(file.read())
        else:
            version, root = game_version(game), (DICT, [])
        with open(out, "wb") as file:
            file.write(serialize(version, set_startup(root, settings)))
        return 0
    sys.stderr.write(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
