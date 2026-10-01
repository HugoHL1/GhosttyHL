#!/usr/bin/env python3
"""Combine static libraries into one with Apple's libtool.

GhosttyHL: the libtool of Xcode 27 drops the members of a Zig-made archive
that are not 8-byte aligned, which leaves libghostty without its objects.
This extracts every member as a standalone object first, so alignment
inside the source archives no longer matters.

Usage: combine_static_libs.py OUTPUT INPUT.a...
"""

import os
import subprocess
import sys
import tempfile


def members(path):
    with open(path, "rb") as f:
        data = f.read()
    if not data.startswith(b"!<arch>\n"):
        raise SystemExit(f"{path}: not an ar archive")
    pos = 8
    long_names = b""
    while pos + 60 <= len(data):
        header = data[pos:pos + 60]
        name = header[0:16].decode().rstrip()
        size = int(header[48:58].decode().strip())
        body = data[pos + 60:pos + 60 + size]
        pos += 60 + size + (size & 1)

        if name.startswith("#1/"):
            # BSD long name: stored at the start of the body.
            name_len = int(name[3:])
            name = body[:name_len].rstrip(b"\0").decode()
            body = body[name_len:]
        elif name == "//":
            long_names = body
            continue
        elif name.startswith("/") and name[1:].isdigit():
            # GNU long name: offset into the "//" table.
            start = int(name[1:])
            end = long_names.index(b"/\n", start)
            name = long_names[start:end].decode()
        elif name.endswith("/"):
            name = name[:-1]

        if name in ("", "/") or name.startswith("__.SYMDEF"):
            continue
        yield name, body


def main():
    output, inputs = sys.argv[1], sys.argv[2:]
    with tempfile.TemporaryDirectory() as tmp:
        objects = []
        for i, lib in enumerate(inputs):
            for j, (name, body) in enumerate(members(lib)):
                obj = os.path.join(tmp, f"{i}-{j}-{os.path.basename(name)}")
                with open(obj, "wb") as f:
                    f.write(body)
                objects.append(obj)
        if os.path.exists(output):
            os.remove(output)
        subprocess.run(["libtool", "-static", "-no_warning_for_no_symbols", "-o", output, *objects], check=True)


if __name__ == "__main__":
    main()
