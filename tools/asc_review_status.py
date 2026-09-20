#!/usr/bin/env python3
"""Print the App Store review status of the app version and every in-app purchase.

Read-only. Uses the same App Store Connect API key as tools/ship_testflight.sh
(~/.appstoreconnect/private_keys/AuthKey_<KEY>.p8), so it needs no browser session.

    python3 tools/asc_review_status.py            # human-readable
    python3 tools/asc_review_status.py --json     # machine-readable
"""
import json
import os
import re
import sys
import time
import urllib.request

import jwt

def _ship_setting(name: str) -> str:
    # Single source of truth: the identifiers already configured for uploads.
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ship_testflight.sh")
    with open(script, encoding="utf-8") as handle:
        match = re.search(rf'^{name}="(?:\$\{{{name}:-)?([^"}}]+)', handle.read(), re.MULTILINE)
    return match.group(1) if match else ""


KEY_ID = os.environ.get("ASC_KEY_ID") or _ship_setting("KEY")
ISSUER = os.environ.get("ASC_ISSUER_ID") or _ship_setting("ISS")
APP_ID = os.environ.get("APPLE_ID") or _ship_setting("APPLE_ID")
KEY_PATH = os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")
API = "https://api.appstoreconnect.apple.com"


def _token() -> str:
    now = int(time.time())
    with open(KEY_PATH, encoding="utf-8") as handle:
        private_key = handle.read()
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


def _get(path: str, token: str) -> dict:
    request = urllib.request.Request(API + path, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def collect() -> dict:
    token = _token()
    versions = _get(f"/v1/apps/{APP_ID}/appStoreVersions?include=build&limit=3", token)
    builds = {row["id"]: row["attributes"]["version"] for row in versions.get("included", [])}
    version_rows = []
    for row in versions["data"]:
        build_ref = (row["relationships"].get("build", {}) or {}).get("data") or {}
        version_rows.append({
            "version": row["attributes"]["versionString"],
            "state": row["attributes"].get("appVersionState") or row["attributes"].get("appStoreState"),
            "build": builds.get(build_ref.get("id"), ""),
        })
    submissions = _get(f"/v1/reviewSubmissions?filter[app]={APP_ID}&limit=5", token)
    submission_rows = []
    for row in submissions["data"]:
        items = _get(f"/v1/reviewSubmissions/{row['id']}/items?limit=50", token)
        states: dict = {}
        for item in items["data"]:
            state = item["attributes"]["state"]
            states[state] = states.get(state, 0) + 1
        submission_rows.append({
            "state": row["attributes"]["state"],
            "submitted": row["attributes"].get("submittedDate"),
            "items": len(items["data"]),
            "item_states": states,
        })
    purchases = _get(f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=50", token)
    purchase_rows = [
        {"name": row["attributes"]["name"], "state": row["attributes"]["state"]}
        for row in purchases["data"]
    ]
    return {"versions": version_rows, "submissions": submission_rows, "purchases": purchase_rows}


def main() -> int:
    report = collect()
    if "--json" in sys.argv:
        print(json.dumps(report, ensure_ascii=False, indent=1))
        return 0
    for row in report["versions"]:
        print(f"version {row['version']} (build {row['build']}): {row['state']}")
    for row in report["submissions"]:
        print(f"submission {row['submitted']}: {row['state']} · {row['items']} items {row['item_states']}")
    tally: dict = {}
    for row in report["purchases"]:
        tally[row["state"]] = tally.get(row["state"], 0) + 1
    print(f"in-app purchases: {tally}")
    for row in report["purchases"]:
        if row["state"] not in ("WAITING_FOR_REVIEW", "IN_REVIEW", "APPROVED"):
            print(f"  ! {row['name']}: {row['state']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
