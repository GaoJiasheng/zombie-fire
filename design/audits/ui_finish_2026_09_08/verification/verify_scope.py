#!/usr/bin/env python3
"""Read-only source guard for the authorized UI-only finish."""
import json
import hashlib
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
BASE = '02505b24a7ecffa8dd726eec1163e31ac09be807'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()

def funcs(source):
    parts = re.split(r'(?=^func )', source, flags=re.M)
    return {p.split('(', 1)[0][5:]: p.rstrip() for p in parts if p.startswith('func ')}

def main():
    old = git('show', BASE + ':gameplay/battle/battle.gd')
    new = (ROOT / 'gameplay/battle/battle.gd').read_text()
    before, after = funcs(old), funcs(new)
    changed = {k for k in before.keys() | after.keys() if before.get(k) != after.get(k)}
    allowed = {'_sync_enemy_world_overlay_clearance', '_layout_card_offer_panel',
               '_layout_pause_action_button', '_spawn_character', '_fit_card_offer_panel_to_cards',
               '_build_skill_card', '_skill_short_desc', '_skill_long_desc'}
    assert changed <= allowed, changed - allowed
    # Every function containing deterministic audit state or timing is byte-identical.
    frozen = [k for k, v in before.items() if any(t in v for t in ['_audit_combat_rng', '_gameplay_now_seconds', 'audit_spawn_index'])]
    assert all(before[k] == after[k] for k in frozen)
    def constants(s):
        return dict(re.findall(r'^const (\w+)\s*(:?=.+)$', s, re.M))
    bc, ac = constants(old), constants(new)
    changed_constants = {k for k in bc.keys() | ac.keys() if bc.get(k) != ac.get(k)}
    assert changed_constants <= {'CARD_OFFER_CARDS_POS', 'CARD_OFFER_CARDS_SIZE', 'CARD_OFFER_CARD_WIDTH', 'CARD_OFFER_TEXT_WIDTH', 'CARD_OFFER_COPY_TOP_Y'}
    for path in ['core', 'gameplay/turret', 'gameplay/projectiles', 'data/levels.json',
                 'data/weapons.json', 'data/economy.json', 'data/premium_sets.json',
                 'data/store_products.json', 'design/audits/campaign_progression_fixture_builds.json']:
        assert not git('diff', BASE, '--', path), path
    assert 'const FONT_SCALE := 1.5' in (ROOT / 'ui/ui_kit.gd').read_text()
    fingerprint = subprocess.check_output(['python3', 'tools/free_side_fingerprint.py', '.'], cwd=ROOT, text=True).strip()
    main_fingerprint = subprocess.check_output(['python3', 'tools/free_side_fingerprint.py', '.', 'main'], cwd=ROOT, text=True).strip()
    assert fingerprint == main_fingerprint
    # Shared short explanations are moved verbatim, not newly authored mechanics.
    original_copy = re.findall(r'return (".*")', before['_skill_short_desc'])
    shared_copy = re.findall(r'return (".*")', (ROOT / 'ui/skill_description.gd').read_text())
    assert original_copy == shared_copy
    archived = {}
    for name in ['chip_apocalypse_golden_law_icon', 'pet_apocalypse_skyfalcon_icon']:
        runtime = 'assets/production/sprites/premium/gilded_eclipse/' + name + '.png'
        original = subprocess.check_output(['git', 'show', BASE + ':' + runtime], cwd=ROOT)
        archive = ROOT / ('assets/production/source_refs/rejected_ui26_2026_09_13/' + name + '.png')
        assert archive.read_bytes() == original, 'Original icon must remain recoverable: ' + name
        archived[name] = hashlib.sha256(original).hexdigest()
    result = dict(baseline=BASE, head=git('rev-parse', 'HEAD'), battle_functions=sorted(changed),
                  ui_constants=sorted(changed_constants), deterministic_functions_unchanged=len(frozen),
                  fingerprint=fingerprint, main_fingerprint=main_fingerprint, shared_skill_copy='verbatim',
                  archived_original_icons=archived)
    Path(__file__).with_name('scope_integrity.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
