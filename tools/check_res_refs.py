from pathlib import Path
import re
import sys

root = Path('/Users/gavin/work/zombie-fire').resolve()
missing = []
checked = 0
for path in list(root.rglob('*.gd')) + list(root.rglob('*.tscn')) + list(root.rglob('project.godot')):
    if '.godot' in path.parts or '.git' in path.parts:
        continue
    try:
        text = path.read_text(errors='ignore')
    except Exception:
        continue
    refs = sorted(set(re.findall(r'res://[^\"\'\)\]\s]+', text)))
    for ref in refs:
        checked += 1
        # ignore %d/%s template refs
        if '%' in ref:
            continue
        target = root / ref.removeprefix('res://')
        if not target.exists():
            missing.append((str(path.relative_to(root)), ref))
print(f"checked {checked} res:// references")
if missing:
    print(f"missing {len(missing)}")
    for owner, ref in missing:
        print(f"  {owner}: {ref}")
    sys.exit(1)
print("res:// references OK")
