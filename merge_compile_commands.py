#!/usr/bin/env python3
import json, os, glob

ws = os.getcwd()
build_dir = os.path.join(ws, "build")

all_entries = []
seen = set()

for path in glob.glob(os.path.join(build_dir, "*", "compile_commands.json")):
    try:
        entries = json.load(open(path))
    except Exception:
        continue

    for e in entries:
        # De-dup by (file, command/directory) to avoid duplicates from overlays
        key = (
            e.get("file"),
            e.get("directory"),
            e.get("command") or " ".join(e.get("arguments", [])),
        )
        if key in seen:
            continue
        seen.add(key)

        # Optional normalization: keep as-is; clangd can handle absolute paths.
        all_entries.append(e)

out = os.path.join(ws, "compile_commands.json")
with open(out, "w") as f:
    json.dump(all_entries, f, indent=2)
print(f"Wrote {out} with {len(all_entries)} entries.")
