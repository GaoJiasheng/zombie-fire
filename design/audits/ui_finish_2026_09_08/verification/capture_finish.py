#!/usr/bin/env python3
"""Replay immutable baseline cases through the existing quiet read-only path."""
import argparse
import hashlib
import importlib.util
import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
AUDIT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'design/audits/ui_full_review_2026_09_08'
spec = importlib.util.spec_from_file_location('capture', BASE / 'verification/capture_audit.py')
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)

PILOT = {
    'core_1080x1920_zh_neon_tempest_menu',
    'core_1080x1920_en_gilded_eclipse_menu',
    'core_1080x1920_en_neon_tempest_settings',
    'core_750x1334_en_neon_tempest_pause',
    'core_1080x1920_en_gilded_eclipse_pause',
    'core_1080x1920_en_default_result',
    'core_1080x1920_en_default_loadout',
    'core_1080x1920_en_default_collection_weapons',
    'core_1080x1920_zh_default_map',
    'normal_store_owned_en_1080x1920',
    'info_privacy_en_750x1334',
    'info_support_en_1080x1920',
    'typography_tall_en_card_offer_1',
    'outfit_options_vanguard_en_scroll0',
    'owned_detail_chips_chip_apocalypse_superconductive_en_scroll0',
    'typography_tall_en_chips_detail_chip_guardian',
    'core_1080x1920_en_neon_tempest_loadout',
    'core_1080x1920_zh_default_collection_skills',
    'core_1080x1920_en_default_collection_skills',
    'final_combat_default_frost_autocannon_center',
    'final_combat_default_vanguard_autocannon_center',
    'loadout_presentation_polar_aurora_vanguard_weapon_autocannon',
    'typography_tall_en_card_offer_5',
    'owned_detail_chips_chip_apocalypse_golden_law_en_scroll0',
    'owned_detail_pets_pet_apocalypse_skyfalcon_en_scroll0',
    'typography_tall_en_card_detail_skill_critical',
    'typography_tall_en_card_detail_skill_barrier',
    'typography_tall_en_card_detail_skill_charge_shot',
}

def runtime_diff():
    return subprocess.check_output(['git', 'diff', '--binary', '--', 'meta', 'ui', 'gameplay', 'core', 'data', 'assets', 'tools'], cwd=ROOT)

def source_manifest():
    paths = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', 'meta', 'ui', 'gameplay', 'core', 'data', 'assets', 'tools'], cwd=ROOT, text=True).splitlines()
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sorted(set(paths)) if (ROOT / p).is_file() and not p.endswith('.import')}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('revision')
    parser.add_argument('--all', action='store_true')
    parser.add_argument('--supplement', action='store_true', help='Every store/loadout route and collection/pets case')
    parser.add_argument('--continuation', action='store_true', help='Sealed base remainder plus every affected case')
    parser.add_argument('--resume', action='store_true', help='Resume only with identical HEAD and source hashes')
    parser.add_argument('--retry-exit-cleanup', action='store_true', help='Archive/retry only known non-deterministic shutdown resource errors')
    args = parser.parse_args()
    target = AUDIT / args.revision
    target.mkdir(exist_ok=args.resume)
    (target / 'verification').mkdir(exist_ok=args.resume)
    (target / 'screenshots').mkdir(exist_ok=args.resume)
    (target / 'screenshots/.gdignore').touch()
    cases = []
    for sidecar in sorted((BASE / 'screenshots').rglob('*.json')):
        row = json.loads(sidecar.read_text())
        affected = row['route'] in ['store', 'loadout'] or (row['route'] == 'collection' and row['payload'].get('mode') == 'pets')
        if args.all or (affected if args.supplement else row['label'] in PILOT):
            cases.append(dict(group='after', route=row['route'], label=row['label'], payload=row['payload'], before=row['file']))
    if args.continuation:
        cases = json.loads((AUDIT / 'verification/final_continuation_cases.json').read_text())
    missing = PILOT - {r['label'] for r in cases}
    if missing and not args.supplement and not args.continuation:
        print('Pilot labels not found:', sorted(missing))
    snapshot = runtime_diff()
    sources = source_manifest()
    if args.resume:
        provenance = json.loads((target / 'verification/provenance.json').read_text())
        head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
        if provenance['head'] != head or (target / 'verification/runtime.patch').read_bytes() != snapshot or json.loads((target / 'verification/source_manifest.json').read_text()) != sources:
            raise RuntimeError('Resume refused: captured HEAD or runtime sources have changed')
    if args.retry_exit_cleanup:
        if not args.resume:
            raise RuntimeError('Cleanup retry requires a sealed, identical-source resume')
        archive = target / 'verification/exit_cleanup_retries'
        for record in sorted((target / 'screenshots').rglob('*.json')):
            log = record.with_suffix('.log')
            errors = re.findall(r'^.*(?:ERROR:|SCRIPT ERROR:|Parse Error:).*$', log.read_text(), re.M)
            if not errors:
                continue
            if not all(re.fullmatch(r'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.', line) for line in errors):
                raise RuntimeError('Unexpected error needs diagnosis, not automatic retry: ' + str(log))
            previous = list(archive.glob(record.stem + '/attempt_*')) if archive.exists() else []
            if len(previous) >= 2:
                raise RuntimeError('Repeated cleanup failure after two retries: ' + record.stem)
            destination = archive / record.stem / ('attempt_' + str(len(previous) + 1))
            destination.mkdir(parents=True)
            for extension in ['.json', '.log', '.png']:
                source = record.with_suffix(extension)
                if source.exists():
                    shutil.move(str(source), str(destination / source.name))
            print('Archived cleanup-error capture before identical-source retry: ' + record.stem, flush=True)
    (target / 'verification/runtime.patch').write_bytes(snapshot)
    (target / 'verification/source_manifest.json').write_text(json.dumps(sources, indent=2))
    (target / 'verification/provenance.json').write_text(json.dumps(dict(head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),diff_sha256=hashlib.sha256(snapshot).hexdigest(),cases=len(cases)), indent=2))
    path = target / 'cases.json'
    path.write_text(json.dumps(cases, ensure_ascii=False, indent=2))
    capture.AUDIT = target
    original_capture = capture.visual.capture
    def retry_timeout(route, payload, out_path):
        for attempt in range(1, 4):
            result = original_capture(route, payload, out_path)
            if result[0] != 124 or attempt == 3:
                return result
            retry_log = target / 'verification/capture_retries.json'
            retries = json.loads(retry_log.read_text()) if retry_log.exists() else []
            retries.append(dict(label=out_path.stem, attempt=attempt, exit=124, log=result[2], timestamp=time.time()))
            retry_log.write_text(json.dumps(retries, ensure_ascii=False, indent=2))
            print(f'Timeout recorded: {out_path.stem}; retry identical configuration ({attempt}/2).', flush=True)
            # A timed-out child is reaped by subprocess.run; still enforce the
            # global one-Godot rule before trying again.
            while True:
                ps = subprocess.check_output(['ps', 'ax', '-o', 'pid=,comm='], text=True)
                if not any(Path(line.split(maxsplit=1)[-1]).name.lower() in ('godot', 'godotquiet') for line in ps.splitlines()):
                    break
                time.sleep(10)
    capture.visual.capture = retry_timeout
    sys.argv = [__file__, '--case-file', str(path)]
    result = capture.main()
    if runtime_diff() != snapshot:
        raise RuntimeError('Runtime changed during capture: discard this revision as acceptance evidence')
    if source_manifest() != sources:
        raise RuntimeError('Source hashes changed during capture, including untracked runtime files')
    return result

if __name__ == '__main__':
    raise SystemExit(main())
