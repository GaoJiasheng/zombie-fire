#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNTIME_ROOTS = ("core", "meta", "gameplay", "ui")
CJK = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]")
PLACEHOLDER = re.compile(r"%(?:[-+ 0#]*\d*(?:\.\d+)?[diouxXeEfFgGsc])")
TRANSLATION_FILES = {
	"localization_zh.json",
	"localization_en.json",
	"localization_ui_en.json",
	"localization_gameplay_en.json",
	"localization_story_en.json",
}
CATALOG_FILES = (
    "localization_ui_en.json",
    "localization_gameplay_en.json",
    "localization_story_en.json",
)


def _gd_string_literals(text: str) -> list[str]:
    """Read double-quoted literals while ignoring GDScript line comments."""
    literals: list[str] = []
    for line in text.splitlines():
        in_string = False
        escaped = False
        code: list[str] = []
        for character in line:
            if in_string:
                code.append(character)
                if escaped:
                    escaped = False
                elif character == "\\":
                    escaped = True
                elif character == '"':
                    in_string = False
            else:
                if character == "#":
                    break
                code.append(character)
                if character == '"':
                    in_string = True
        for match in re.finditer(r'"((?:[^"\\]|\\.)*)"', "".join(code)):
            literals.append(match.group(1).replace(r"\n", "\n"))
    return literals


def _walk_json(value: object) -> list[str]:
    result: list[str] = []
    if isinstance(value, dict):
        for child in value.values():
            result.extend(_walk_json(child))
    elif isinstance(value, list):
        for child in value:
            result.extend(_walk_json(child))
    elif isinstance(value, str):
        result.append(value)
    return result


def collect_sources() -> dict[str, set[str]]:
    locations: dict[str, set[str]] = defaultdict(set)
    for root_name in RUNTIME_ROOTS:
        for path in (ROOT / root_name).rglob("*"):
            if path.suffix not in {".gd", ".tscn"}:
                continue
            for literal in _gd_string_literals(path.read_text(errors="ignore")):
                if CJK.search(literal):
                    locations[literal].add(str(path.relative_to(ROOT)))
    for path in sorted((ROOT / "data").glob("*.json")):
        if path.name in TRANSLATION_FILES:
            continue
        parsed = json.loads(path.read_text())
        for value in _walk_json(parsed):
            if CJK.search(value):
                locations[value].add(str(path.relative_to(ROOT)))
    return locations


def _translate_with_terms(source: str, terms: dict[str, str]) -> str:
    result = source
    for term in sorted(terms, key=len, reverse=True):
        result = result.replace(term, terms[term])
    return result


def _placeholders(value: str) -> list[str]:
    return PLACEHOLDER.findall(value.replace("%%", ""))


def main() -> int:
    errors: list[str] = []
    zh = json.loads((ROOT / "data/localization_zh.json").read_text())
    en = json.loads((ROOT / "data/localization_en.json").read_text())
    missing_ids = sorted(set(zh) - set(en))
    extra_ids = sorted(set(en) - set(zh))
    if missing_ids:
        errors.append(f"localization_en.json missing ids: {', '.join(missing_ids)}")
    if extra_ids:
        errors.append(f"localization_en.json has unknown ids: {', '.join(extra_ids)}")
    for key, value in en.items():
        if not str(value).strip() or CJK.search(str(value)):
            errors.append(f"localization_en.json invalid English value for {key}: {value}")

    catalog: dict[str, str] = {}
    terms: dict[str, str] = {}
    for filename in CATALOG_FILES:
        part = json.loads((ROOT / "data" / filename).read_text())
        part_terms = part.pop("__terms", {})
        terms.update(part_terms)
        catalog.update(part)
    if not isinstance(terms, dict):
        errors.append("localization_ui_en.json __terms must be an object")
        terms = {}
    for source, target in {**catalog, **terms}.items():
        if not str(target).strip() or CJK.search(str(target)):
            errors.append(f"English catalog target still contains CJK: {source} -> {target}")
    for source, target in catalog.items():
        if len(_placeholders(source)) != len(_placeholders(str(target))):
            errors.append(f"placeholder mismatch: {source} -> {target}")

    locations = collect_sources()
    missing: list[str] = []
    for source in sorted(locations):
        translated = str(catalog[source]) if source in catalog else _translate_with_terms(source, terms)
        if not translated.strip() or CJK.search(translated):
            remainder = "".join(sorted(set(CJK.findall(translated))))
            missing.append(
                f"{source.replace(chr(10), ' / ')} [{', '.join(sorted(locations[source]))}]"
                f" remaining={remainder}"
            )
    if missing:
        errors.append(f"{len(missing)} runtime Chinese strings lack complete English coverage:")
        errors.extend(missing[:300])
        if len(missing) > 300:
            errors.append(f"... and {len(missing) - 300} more")

    project_text = (ROOT / "project.godot").read_text()
    if 'LocalizationManager="*res://core/localization/localization_manager.gd"' not in project_text:
        errors.append("LocalizationManager autoload is missing")
    settings_scene = (ROOT / "meta/settings/settings.tscn").read_text()
    if 'name="LanguageButton"' not in settings_scene:
        errors.append("Settings screen has no language selector")

    if errors:
        print("Localization check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(
        "Localization check OK: "
        f"{len(en)} content ids, {len(catalog)} exact messages, "
        f"{len(terms)} reusable terms, {len(locations)} runtime Chinese sources"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
