#!/usr/bin/env python3
"""Log every actual read-only static gate; preserve failures, no data writer."""
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
DATE = '2026_10_04'
COMMANDS = [
    ['tools/test_resource_curves.py'],
    ['tools/test_linear_power_program.py'],
    ['tools/test_derive_recommended_power.py'],
    ['tools/test_linear_power_acceptance.py'],
    ['tools/test_frontline_sweep_metadata.py'],
    ['tools/validate_asset_pack.py'],
    ['tools/validate_data.py'],
    ['tools/check_res_refs.py'],
    ['tools/check_level_pressure.py'],
    ['tools/simulate_card_director.py'],
    ['tools/check_clear_requirements.py'],
    ['tools/test_power_scale_v6.py'],
    ['tools/check_campaign_pacing_contract.py'],
    ['tools/audit_campaign_frontline.py', '--check'],
    ['tools/report_fire_rate_tier_comparison.py', '--check'],
    ['tools/report_frontline_calibration.py', '--check'],
    ['tools/generate_weapon_power_profiles.py', '--check'],
    ['tools/audit_free_elemental_weapons.py', '--check'],
    ['tools/check_localization.py'],
    ['tools/check_endgame_balance.py'],
    ['tools/check_economy_loop.py'],
]


def main():
    results = []
    for parts in COMMANDS:
        command = [sys.executable, *parts]
        log = Path(f'/tmp/zf_linear_acceptance_static_{Path(parts[0]).stem}_{DATE}.log')
        if log.exists():
            raise RuntimeError(f'refuse to overwrite prior log: {log}')
        with log.open('w') as handle:
            proc = subprocess.run(command, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT)
        result = {'command': command, 'exit': proc.returncode,
                  'result': 'PASS' if proc.returncode == 0 else 'FAIL', 'log': str(log)}
        results.append(result)
        print(f"{result['result']} exit={proc.returncode} {' '.join(parts)} log={log}", flush=True)
    output = ROOT/f'design/audits/linear_power_p2_{DATE}/acceptance_static_verification_{DATE}.json'
    output.write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n')
    return int(any(r['exit'] for r in results))


if __name__ == '__main__':
    raise SystemExit(main())
