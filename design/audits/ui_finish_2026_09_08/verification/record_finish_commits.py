#!/usr/bin/env python3
"""Record the exact focused product commits; never stage or commit anything."""
import json
import re
import subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
BASE = '02505b24a7ecffa8dd726eec1163e31ac09be807'
CODE_HEAD = 'b32841b7ed7aaf52aa1970e80bed28ec844ab0ef'
def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()
rows = []
for line in git('log', '--reverse', '--format=%H%x09%s', BASE + '..' + CODE_HEAD).splitlines():
    head, message = line.split('\t', 1)
    match = re.match(r'fix\(([^)]+)\):', message)
    assert match, message
    rows.append(dict(id=match[1], head=head, message=message, files=git('diff-tree', '--no-commit-id', '--name-only', '-r', head).splitlines()))
assert len(rows) == 23
Path(__file__).with_name('commits.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2))
Path(__file__).with_name('commit_log.txt').write_text(git('log', '--reverse', '--oneline', BASE + '..' + CODE_HEAD) + '\n')
print(f'{len(rows)} focused commits; code HEAD {CODE_HEAD}')
