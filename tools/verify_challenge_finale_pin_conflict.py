#!/usr/bin/env python3
"""Read-only proof of the L099 curve/legacy validation authority conflict.

In-memory examples are diagnostics, not adopted curves or runtime wins.
"""
import copy
import hashlib
import json
from pathlib import Path

from challenge_curve import rule_for_level, validate

ROOT = Path(__file__).resolve().parents[1]


def main():
    path = ROOT / 'data/challenges.json'
    before = path.read_bytes()
    current = json.loads(before)
    assert not validate(current)
    original = rule_for_level(99, current)
    interior = copy.deepcopy(current)
    for row in interior['curve']['anchors'][1:-1]:
        row['k'] = (row['k'] + 5.0) / 2
    for row in interior['curve']['line_pressure_exponents']['anchors'][1:-1]:
        row.update(speed=0.5, breach=0.25, mechanic=0.25)
    unchanged = rule_for_level(99, interior)
    assert original == unchanged, 'interior must not affect exact endpoint'
    examples = []
    for label in ('K_5_2', 'split_098_001_001'):
        candidate = copy.deepcopy(current)
        if label == 'K_5_2':
            candidate['curve']['anchors'][-1]['k'] = 5.2
        else:
            candidate['curve']['line_pressure_exponents']['anchors'][-1].update(
                speed=0.98, breach=0.01, mechanic=0.01)
        errors = validate(candidate)
        assert errors, 'legacy endpoint gate must reject the diagnostic'
        examples.append({'label': label, 'runtime_rule': rule_for_level(99, candidate),
                         'legacy_validation_errors': errors,
                         'runtime_tested': False, 'adopted': False})
    assert path.read_bytes() == before
    print(json.dumps({
        'status': 'PROOF_PASS_AUTHORITY_DECISION_PENDING',
        'product_data_written': False,
        'challenge_sha256': hashlib.sha256(before).hexdigest(),
        'current_L099_rule': original,
        'interior_changes_leave_L099_identical': True,
        'diagnostic_examples': examples,
        'note': 'No proposed K/split is validated as a replacement. '
                'Current fixed endpoint plus unchanged fixture/probe cannot be retuned '
                'by interior knots; Owner/Fable must resolve legacy numeric pins '
                'versus the authorized curve-only retune before adoption.'
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
