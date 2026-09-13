#!/usr/bin/env python3
"""Record the handoff commit and prove no runtime bytes changed after capture."""
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
AUDIT = Path(__file__).resolve().parents[1]

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()

def main():
    provenance = json.loads((AUDIT / 'supplement01/verification/provenance.json').read_text())
    captured = json.loads((AUDIT / 'supplement01/verification/source_manifest.json').read_text())
    paths = git('ls-files', '--cached', '--others', '--exclude-standard', '--', 'meta', 'ui', 'gameplay', 'core', 'data', 'assets', 'tools').splitlines()
    current = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in set(paths) if (ROOT / p).is_file() and not p.endswith('.import')}
    assert captured == current, 'Runtime sources differ from accepted capture'
    assert not git('diff', '--', 'meta', 'ui', 'gameplay', 'core', 'data', 'assets', 'tools')
    result = dict(branch=git('branch', '--show-current'), head=git('rev-parse', 'HEAD'),
                  code_head=provenance['head'], unchanged_runtime_after_capture=True,
                  tracked_changes=git('status', '--short', '--untracked-files=no').splitlines(),
                  untracked_files=git('ls-files', '--others', '--exclude-standard').splitlines(),
                  pushed=False, testflight_built=False)
    (AUDIT / 'verification/final_git_state.json').write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(json.dumps({k: v for k, v in result.items() if k != 'untracked_files'}, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
