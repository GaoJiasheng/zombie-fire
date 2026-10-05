"""2026-10 runtime_solved 方向 A: approved Table B, requirement side only."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = ROOT / 'data/campaign_pacing_targets.json'


def enabled() -> bool:
    return json.loads(TARGETS.read_text()).get('clear_requirement_mode') == 'runtime_solved'


def table() -> dict[int, dict]:
    targets = json.loads(TARGETS.read_text())
    path = (ROOT / targets['runtime_recommended_power_table']).resolve()
    if not path.is_relative_to(ROOT / 'design/audits'):
        raise ValueError('approved Table B must be in design/audits')
    payload = json.loads(path.read_text())
    if payload.get('status') != 'gate_B_ratified_2026_10_04' or payload.get('violations') or payload.get('fable_fixed_mismatches'):
        raise ValueError('Table B is not ratified or has unresolved violations')
    rows = {int(row['level']): row for row in payload['rows']}
    if len(payload['rows']) != 99 or set(rows) != set(range(1, 100)):
        raise ValueError('Table B must cover 99 distinct levels')
    for n, row in rows.items():
        rec, p = row['recommended_power'], row.get('p_star')
        if not isinstance(rec, int) or rec < 50 or (p is not None and not p <= rec <= round(1.35 * p)):
            raise ValueError(f'L{n:03d}: approved truth bounds violated')
    return rows
