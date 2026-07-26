#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
import tempfile
from datetime import datetime, timezone
from pathlib import Path


UUID_PATTERN = r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
DELIVERY_PATTERNS = (
    re.compile(rf"\bdelivery(?:[\s_-]+)(?:uuid|id)\b\s*[:=]\s*({UUID_PATTERN})", re.IGNORECASE),
    re.compile(rf"\brequest(?:[\s_-]*)uuid\b\s*[:=]\s*({UUID_PATTERN})", re.IGNORECASE),
)


def read_text(path: Path) -> str:
    if not path.is_file():
        raise ValueError(f"log file does not exist: {path}")
    return path.read_text(encoding="utf-8", errors="replace")


def extract_delivery_id(text: str) -> str:
    for pattern in DELIVERY_PATTERNS:
        matches = pattern.findall(text)
        if matches:
            unique = list(dict.fromkeys(match.lower() for match in matches))
            if len(unique) != 1:
                raise ValueError(f"upload log contains conflicting delivery IDs: {unique}")
            return unique[0]

    all_uuids = list(dict.fromkeys(match.lower() for match in re.findall(UUID_PATTERN, text, re.IGNORECASE)))
    if len(all_uuids) == 1:
        return all_uuids[0]
    if not all_uuids:
        raise ValueError("upload log does not contain a delivery UUID")
    raise ValueError(f"upload log contains multiple UUIDs but no labeled delivery ID: {all_uuids}")


def _status_value(text: str, key: str) -> str | None:
    pattern = key.replace("_", r"[-_ ]")
    match = re.search(rf"\b{pattern}\b\s*:\s*([A-Z0-9_.-]+)", text, re.IGNORECASE)
    return match.group(1).upper() if match else None


def _true_marker(text: str, key: str) -> bool:
    value = _status_value(text, key)
    if value is not None:
        return value == "TRUE"
    pattern = key.replace("_", r"[-_ ]")
    return re.search(rf"\b{pattern}\b", text, re.IGNORECASE) is not None


def parse_valid_status(text: str) -> dict[str, object]:
    build_status = _status_value(text, "BUILD_STATUS")
    import_status = _status_value(text, "IMPORT_STATUS")
    delivery_id = _status_value(text, "DELIVERY_UUID")
    reported_build = _status_value(text, "VERSION")
    encryption_value = _status_value(text, "USES_NON_EXEMPT_ENCRYPTION")
    app_store_eligible = _true_marker(text, "APP_STORE_ELIGIBLE")
    on_app_store_connect = _true_marker(text, "IS_ON_APP_STORE_CONNECT")

    failures: list[str] = []
    if build_status != "VALID":
        failures.append(f"BUILD-STATUS={build_status or 'missing'}")
    if import_status != "VALID":
        failures.append(f"IMPORT-STATUS={import_status or 'missing'}")
    if not app_store_eligible:
        failures.append("APP_STORE_ELIGIBLE is not true")
    if not on_app_store_connect:
        failures.append("IS-ON-APP-STORE-CONNECT is not true")
    if delivery_id is None or re.fullmatch(UUID_PATTERN, delivery_id, re.IGNORECASE) is None:
        failures.append("DELIVERY-UUID is missing or invalid")
    if reported_build is None or not reported_build.isdigit():
        failures.append("VERSION is missing or invalid")
    if encryption_value not in {"FALSE", "0"}:
        failures.append(f"USES-NON-EXEMPT-ENCRYPTION={encryption_value or 'missing'}")
    if failures:
        raise ValueError("Apple build status is not release-ready: " + ", ".join(failures))

    return {
        "build_status": build_status,
        "import_status": import_status,
        "reported_delivery_id": str(delivery_id).lower(),
        "reported_build": int(str(reported_build)),
        "app_store_eligible": app_store_eligible,
        "on_app_store_connect": on_app_store_connect,
        "uses_non_exempt_encryption": False,
    }


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def artifact_record(path: Path, root: Path) -> dict[str, object]:
    if not path.is_file() or path.stat().st_size <= 0:
        raise ValueError(f"release artifact is missing or empty: {path}")
    resolved = path.resolve()
    try:
        display_path = str(resolved.relative_to(root.resolve()))
    except ValueError:
        display_path = str(resolved)
    return {
        "path": display_path,
        "bytes": resolved.stat().st_size,
        "sha256": sha256(resolved),
    }


def write_manifest(args: argparse.Namespace) -> dict[str, object]:
    upload_log = Path(args.upload_log)
    status_log = Path(args.status_log)
    delivery_id = extract_delivery_id(read_text(upload_log))
    if args.expected_delivery_id and delivery_id != args.expected_delivery_id.lower():
        raise ValueError(
            f"delivery ID changed between upload and status lookup: "
            f"expected {args.expected_delivery_id.lower()}, got {delivery_id}"
        )
    delivery_status = parse_valid_status(read_text(status_log))
    if delivery_status["reported_delivery_id"] != delivery_id:
        raise ValueError(
            f"Apple status returned delivery {delivery_status['reported_delivery_id']}, "
            f"but the upload log returned {delivery_id}"
        )
    if delivery_status["reported_build"] != int(args.build):
        raise ValueError(
            f"Apple status returned build {delivery_status['reported_build']}, "
            f"but the release expected build {args.build}"
        )
    root = Path(args.project_root)
    source_commit = args.source_commit.lower()
    if re.fullmatch(r"[0-9a-f]{40}", source_commit) is None:
        raise ValueError(f"source commit must be a full 40-character SHA-1: {args.source_commit}")

    manifest = {
        "schema_version": 1,
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "source": {
            "git_commit": source_commit,
            "tracked_changes_present": bool(args.source_dirty),
        },
        "app": {
            "apple_id": str(args.apple_id),
            "bundle_id": args.bundle_id,
            "short_version": args.short_version,
            "build": int(args.build),
        },
        "delivery": {
            "delivery_id": delivery_id,
            **delivery_status,
        },
        "artifacts": {
            "ipa": artifact_record(Path(args.ipa), root),
            "pck": artifact_record(Path(args.pck), root),
        },
    }

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        dir=output.parent,
        prefix=f".{output.name}.",
        suffix=".tmp",
        delete=False,
    ) as handle:
        temporary = Path(handle.name)
        json.dump(manifest, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    temporary.replace(output)
    return manifest


def run_self_test() -> None:
    delivery_id = "a90cad41-f8b8-4287-8d27-48b679e8d352"
    upload = f"Delivery UUID: {delivery_id}\nUPLOAD SUCCEEDED with no errors\n"
    status = (
        "BUILD-STATUS: VALID\n"
        f"DELIVERY-UUID: {delivery_id}\n"
        "BUILD-AUDIENCE-TYPE: APP_STORE_ELIGIBLE\n"
        "IMPORT-STATUS: VALID\n"
        "IS-ON-APP-STORE-CONNECT: true\n"
        "USES-NON-EXEMPT-ENCRYPTION: false\n"
        "VERSION: 36\n"
    )
    assert extract_delivery_id(upload) == delivery_id
    parsed = parse_valid_status(status)
    assert parsed["app_store_eligible"] is True

    try:
        parse_valid_status(status.replace("IMPORT-STATUS: VALID", "IMPORT-STATUS: FAILED"))
    except ValueError:
        pass
    else:
        raise AssertionError("invalid Apple import status was accepted")

    with tempfile.TemporaryDirectory() as raw_dir:
        root = Path(raw_dir)
        upload_log = root / "upload.log"
        status_log = root / "status.log"
        ipa = root / "ZombieFire.ipa"
        pck = root / "ZombieFire.pck"
        output = root / "release_manifest.json"
        upload_log.write_text(upload, encoding="utf-8")
        status_log.write_text(status, encoding="utf-8")
        ipa.write_bytes(b"audited ipa")
        pck.write_bytes(b"audited pck")
        args = argparse.Namespace(
            upload_log=str(upload_log),
            status_log=str(status_log),
            expected_delivery_id=delivery_id,
            project_root=str(root),
            source_commit="1" * 40,
            source_dirty=0,
            apple_id="6785918342",
            bundle_id="com.gaojiasheng.zombiefire",
            short_version="1.0.0",
            build=36,
            ipa=str(ipa),
            pck=str(pck),
            output=str(output),
        )
        manifest = write_manifest(args)
        assert output.is_file()
        assert manifest["delivery"]["delivery_id"] == delivery_id
        assert manifest["delivery"]["reported_build"] == 36
        assert manifest["artifacts"]["ipa"]["sha256"] == hashlib.sha256(b"audited ipa").hexdigest()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Extract an App Store delivery ID and write an audited TestFlight release manifest."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    extract = subparsers.add_parser("extract-delivery-id")
    extract.add_argument("--upload-log", required=True)

    write = subparsers.add_parser("write")
    write.add_argument("--upload-log", required=True)
    write.add_argument("--status-log", required=True)
    write.add_argument("--expected-delivery-id")
    write.add_argument("--project-root", required=True)
    write.add_argument("--source-commit", required=True)
    write.add_argument("--source-dirty", type=int, choices=(0, 1), required=True)
    write.add_argument("--apple-id", required=True)
    write.add_argument("--bundle-id", required=True)
    write.add_argument("--short-version", required=True)
    write.add_argument("--build", type=int, required=True)
    write.add_argument("--ipa", required=True)
    write.add_argument("--pck", required=True)
    write.add_argument("--output", required=True)

    subparsers.add_parser("self-test")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "extract-delivery-id":
            print(extract_delivery_id(read_text(Path(args.upload_log))))
        elif args.command == "write":
            manifest = write_manifest(args)
            print(
                "Release delivery record OK: "
                f"{manifest['app']['short_version']} ({manifest['app']['build']}) / "
                f"{manifest['delivery']['delivery_id']}"
            )
        else:
            run_self_test()
            print("Release delivery record self-test OK")
    except (OSError, ValueError, AssertionError) as exc:
        print(f"Release delivery record failed: {exc}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
