#!/usr/bin/env python3
"""Read or write a waybar config.json.  Usage:
  waybar-edit.py read  <config>               -> JSON to stdout
  waybar-edit.py write <config> <patch.json>  -> deep-merge patch into config, write atomically
"""
import json, sys, os

def deep_merge(base, patch):
    out = dict(base)
    for k, v in patch.items():
        if k in out and isinstance(out[k], dict) and isinstance(v, dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = v
    return out

def write_atomic(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)

def read_patch(arg):
    if arg.startswith("{") or arg.startswith("["):
        return json.loads(arg)
    with open(arg) as f:
        return json.load(f)

def main():
    if len(sys.argv) < 3:
        print("Usage: waybar-edit.py read|write <config> [patch.json]", file=sys.stderr)
        sys.exit(2)
    action, config = sys.argv[1], sys.argv[2]
    with open(config) as f:
        data = json.load(f)
    if action == "read":
        json.dump(data, sys.stdout, indent=2, ensure_ascii=False)
        sys.stdout.write("\n")
    elif action == "write" and len(sys.argv) > 3:
        patch = read_patch(sys.argv[3])
        data = deep_merge(data, patch)
        write_atomic(config, data)
        print("OK")
    else:
        print(json.dumps({"error": f"bad action: {action}"}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
