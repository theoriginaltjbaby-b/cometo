#!/usr/bin/env python3
"""Concatenate every text source file into docs/ALL_SOURCE.txt for reviewers and
tools that cannot browse the repo. Run from the project root:
    python3 tools/bundle_source.py
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "ALL_SOURCE.txt")
EXTS = (".gd", ".gdshader", ".json", ".tscn", ".godot", ".py", ".sh")
SKIP_DIRS = {".git", ".godot", "export", "docs"}

paths = []
for base, dirs, files in os.walk(ROOT):
    dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
    for f in sorted(files):
        if f.endswith(EXTS):
            paths.append(os.path.relpath(os.path.join(base, f), ROOT))

with open(OUT, "w") as out:
    out.write("COMETO - all source files. Index:\n")
    for p in paths:
        out.write("  %s\n" % p)
    for p in paths:
        out.write("\n\n" + "=" * 78 + "\n== %s\n" % p + "=" * 78 + "\n")
        with open(os.path.join(ROOT, p)) as f:
            out.write(f.read())
print("wrote %s (%d files)" % (os.path.relpath(OUT, ROOT), len(paths)))
