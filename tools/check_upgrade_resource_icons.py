#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    ui_kit = read("ui/ui_kit.gd")
    save = read("core/save/save_manager.gd")
    collection = read("meta/collection/collection.gd")
    store = read("meta/store/store.gd")
    failures: list[str] = []

    icon_contract = {
        "gold": "icon_currency_gold.png",
        "xp": "icon_currency_xp.png",
        "star": "icon_currency_star.png",
        "talent_point": "icon_talent_point.png",
        "reroll_charge": "icon_reroll_charge.png",
    }
    for kind, filename in icon_contract.items():
        if f'"{kind}"' not in ui_kit or filename not in ui_kit:
            failures.append(f"UiKit currency icon routing is missing {kind} -> {filename}")

    required_cost_specs = {
        "get_item_upgrade_cost_spec": "gold",
        "get_unlock_cost_spec": "star",
        "get_skill_base_upgrade_cost_spec": "xp",
        "get_sig_skill_upgrade_cost_spec": "xp",
    }
    for function_name, kind in required_cost_specs.items():
        pattern = rf"func {function_name}\([^\n]*\)[^\n]*\n\s*return \{{\"kind\": \"{kind}\""
        if re.search(pattern, save) is None:
            failures.append(f"SaveManager {function_name} must declare the real {kind} resource")

    if "static func apply_resource_cost(" not in ui_kit:
        failures.append("UiKit must expose the shared structured resource-cost component")
    if 'button.set_meta("cost_resource_kind", resource_kind)' not in ui_kit:
        failures.append("structured resource-cost buttons must expose their resource kind for runtime audit")

    expected_ui_routes = [
        (collection, 'get_unlock_cost_spec', "collection unlocks must use star cost specs"),
        (collection, 'get_item_upgrade_cost_spec', "collection equipment and character upgrades must use gold cost specs"),
        (collection, 'get_skill_base_upgrade_cost_spec', "generic skill upgrades must use XP cost specs"),
        (collection, 'get_sig_skill_upgrade_cost_spec', "signature skill upgrades must use XP cost specs"),
        (store, 'get_item_upgrade_cost_spec', "owned premium equipment upgrades must use gold cost specs"),
    ]
    for source, marker, message in expected_ui_routes:
        if marker not in source:
            failures.append(message)
    if collection.count("UiKit.apply_resource_cost(") < 5:
        failures.append("collection must render structured costs for list unlock, detail unlock, equipment, generic skill and signature skill actions")
    if "UiKit.apply_resource_cost(" not in store:
        failures.append("premium store owned-item upgrades must render the shared gold cost component")

    # Star rating glyphs remain legitimate on level-progress UI. They are not a
    # currency icon and therefore may never reappear in collection purchase or
    # upgrade button copy.
    forbidden_button_copy = [
        (collection, r"%d\s*★", "collection cost copy must not use a star glyph as a pseudo-icon"),
        (collection, r'_(?:detail_button|armored_action_button)\([^\n]*"升级[^\n\"]*%d', "collection upgrade buttons must not combine action and numeric cost in one string"),
        (store, r'upgrade\.text\s*=.*升级[^\n\"]*%d', "store upgrade buttons must not combine action and numeric cost in one string"),
        (store, r"Upgrade[^\n\"]*%d\s+Gold", "store upgrade buttons must not spell out Gold instead of rendering its logo"),
    ]
    for source, pattern, message in forbidden_button_copy:
        if re.search(pattern, source):
            failures.append(message)

    if '"cost_kind": "star"' not in collection:
        failures.append("collection purchase confirmation must derive its icon from the star resource kind")

    if failures:
        print("Upgrade resource icon check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Upgrade resource icon check passed: gold, XP, star and extensible resource costs use matching logos.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
