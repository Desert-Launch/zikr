#!/usr/bin/env python3
"""Publish the hourly zekr clips into the two places a notification can read.

`assets/audio/adhan/` is a Flutter asset directory, and neither platform's
notification system can read one: an Android notification channel plays a
`res/raw/` resource, and iOS plays a `.caf` from the app bundle. So every clip
has to exist three times over. This script keeps the two native copies in sync
with the Flutter assets, driven by the `sound` values in
`assets/data/notifictaions/hourly_notifications.json`.

    python3 tool/sync_zikr_sounds.py [--dry-run]

For each `sound` slug in the JSON it:
  1. copies `assets/audio/adhan/<slug>.mp3` to `android/app/src/main/res/raw/`
  2. converts it to `ios/Runner/Sounds/<slug>.caf` via `afconvert` (macOS)
  3. registers that `.caf` in `ios/Runner.xcodeproj/project.pbxproj`

Idempotent: re-running skips native copies that are already newer than their
source and leaves already-registered pbxproj entries alone. A slug with no
source `.mp3` is reported and skipped — `DSHourlyTasbih` falls back to the
silent hourly channel for those, so a partial set is a working app.

Adding or renaming a clip is a JSON edit plus a re-run; nothing here hard-codes
the ten current slugs.

A native resource cannot be added by hot restart — rebuild both apps after this
runs.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

FEED = ROOT / "assets/data/notifictaions/hourly_notifications.json"
ASSET_DIR = ROOT / "assets/audio/adhan"
ANDROID_RAW = ROOT / "android/app/src/main/res/raw"
IOS_SOUNDS = ROOT / "ios/Runner/Sounds"
PBXPROJ = ROOT / "ios/Runner.xcodeproj/project.pbxproj"

# The `Sounds` PBXGroup and the Runner target's resources phase, both of which
# an added .caf has to be listed in to reach the bundle.
SOUNDS_GROUP_ID = "60511E544A7C0CFB3C389F05"
RESOURCES_PHASE_ID = "97C146EC1CF9000F007C117D"

# Android resource names are restricted to [a-z0-9_] and may not lead with a
# digit. A slug that breaks this compiles to a resource the channel can't find,
# which surfaces as a silent notification rather than a build error — so it is
# worth catching here.
ANDROID_RES_NAME = re.compile(r"^[a-z][a-z0-9_]*$")


def load_slugs() -> list[str]:
    """The `sound` slug of every zekr in the feed, in order, deduplicated."""
    root = json.loads(FEED.read_text(encoding="utf-8"))
    slugs: list[str] = []
    for row in root.get("hourly_azkar", []):
        slug = (row or {}).get("sound")
        if slug and slug not in slugs:
            slugs.append(slug)
    return slugs


def sync_android(slug: str, source: Path, dry_run: bool) -> bool:
    """Copy the clip into res/raw. Returns True when it wrote something."""
    dest = ANDROID_RAW / f"{slug}.mp3"
    if dest.exists() and dest.stat().st_mtime >= source.stat().st_mtime:
        return False
    if dry_run:
        print(f"  android: would copy -> {dest.relative_to(ROOT)}")
        return True
    ANDROID_RAW.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, dest)
    print(f"  android: {dest.relative_to(ROOT)}")
    return True


def sync_ios(slug: str, source: Path, dry_run: bool) -> bool:
    """Transcode the clip to a bundle-ready .caf. Returns True when it wrote."""
    dest = IOS_SOUNDS / f"{slug}.caf"
    if dest.exists() and dest.stat().st_mtime >= source.stat().st_mtime:
        return False
    if dry_run:
        print(f"  ios:     would convert -> {dest.relative_to(ROOT)}")
        return True
    if not shutil.which("afconvert"):
        print("  ios:     SKIPPED — afconvert not found (macOS only)")
        return False
    IOS_SOUNDS.mkdir(parents=True, exist_ok=True)
    # IMA4 in a CAF container is what UNNotificationSound expects; the existing
    # adhan clips in this folder use the same encoding.
    subprocess.run(
        ["afconvert", str(source), str(dest), "-d", "ima4", "-f", "caff", "-v"],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    print(f"  ios:     {dest.relative_to(ROOT)}")
    return True


def stable_hex(slug: str, salt: str) -> str:
    """A deterministic 24-hex-char pbxproj object id derived from the slug.

    Xcode only requires these to be unique within the file. Deriving them means
    a re-run produces the same ids, so the registration stays idempotent and the
    file doesn't churn in git.
    """
    import hashlib

    return hashlib.sha1(f"{salt}:{slug}".encode()).hexdigest()[:24].upper()


def register_ios(slugs: list[str], dry_run: bool) -> int:
    """Add missing .caf entries to the Sounds group and the resources phase."""
    text = PBXPROJ.read_text(encoding="utf-8")
    missing = [s for s in slugs if f"{s}.caf */" not in text]
    if not missing:
        return 0
    if dry_run:
        for slug in missing:
            print(f"  pbxproj: would register {slug}.caf")
        return len(missing)

    build_lines, ref_lines, group_lines, phase_lines = [], [], [], []
    for slug in missing:
        file_ref = stable_hex(slug, "fileRef")
        build_id = stable_hex(slug, "buildFile")
        name = f"{slug}.caf"
        build_lines.append(
            f"\t\t{build_id} /* {name} in Resources */ = {{isa = PBXBuildFile; "
            f"fileRef = {file_ref} /* {name} */; }};"
        )
        ref_lines.append(
            f"\t\t{file_ref} /* {name} */ = {{isa = PBXFileReference; "
            f"includeInIndex = 1; lastKnownFileType = file; path = {name}; "
            f'sourceTree = "<group>"; }};'
        )
        group_lines.append(f"{file_ref} /* {name} */,")
        phase_lines.append(f"{build_id} /* {name} in Resources */,")

    text = text.replace(
        "/* End PBXBuildFile section */",
        "\n".join(build_lines) + "\n/* End PBXBuildFile section */",
        1,
    )
    text = text.replace(
        "/* End PBXFileReference section */",
        "\n".join(ref_lines) + "\n/* End PBXFileReference section */",
        1,
    )
    text = insert_into_list(
        text, SOUNDS_GROUP_ID, "children", group_lines, "Sounds group"
    )
    text = insert_into_list(
        text, RESOURCES_PHASE_ID, "files", phase_lines, "resources phase"
    )

    PBXPROJ.write_text(text, encoding="utf-8")
    for slug in missing:
        print(f"  pbxproj: registered {slug}.caf")
    return len(missing)


def insert_into_list(
    text: str, object_id: str, key: str, entries: list[str], label: str
) -> str:
    """Append [entries] to the `key = ( ... );` list of the given pbx object.

    Anchored on the object's *definition* — `<id> /* name */ = {` — and then on
    the named key inside it, rather than on the first `= (` after the id. The
    id also appears wherever the object is referenced (a target's `buildPhases`
    list, for one), and matching there put the first version of this script's
    entries into the target's `buildRules` instead of the resources phase.
    """
    definition = re.search(
        rf"^\t*{object_id} /\* [^*]*\*/ = \{{", text, re.MULTILINE
    )
    if definition is None:
        raise RuntimeError(f"Could not locate the {label} object in the pbxproj")
    key_match = re.compile(rf"^\t*{key} = \(\n", re.MULTILINE).search(
        text, definition.end()
    )
    if key_match is None:
        raise RuntimeError(f"Could not locate `{key}` in the {label}")
    close = text.index(");", key_match.end())
    # Start of the line holding `);`, so entries land above it fully indented
    # rather than glued onto that line's leading tabs.
    line_start = text.rindex("\n", key_match.end(), close) + 1
    block = "".join(f"\t\t\t\t{entry}\n" for entry in entries)
    return text[:line_start] + block + text[line_start:]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="report what would change without writing anything",
    )
    args = parser.parse_args()

    slugs = load_slugs()
    if not slugs:
        print(f"No `sound` slugs in {FEED.relative_to(ROOT)} — nothing to do.")
        return 0

    print(f"{len(slugs)} zekr clip(s) declared in the feed.\n")
    present, missing, changed = [], [], 0
    for slug in slugs:
        if not ANDROID_RES_NAME.match(slug):
            print(f"{slug}: INVALID — Android resource names must match [a-z][a-z0-9_]*")
            missing.append(slug)
            continue
        source = ASSET_DIR / f"{slug}.mp3"
        if not source.exists():
            missing.append(slug)
            continue
        print(f"{slug}")
        present.append(slug)
        changed += int(sync_android(slug, source, args.dry_run))
        changed += int(sync_ios(slug, source, args.dry_run))

    if present:
        changed += register_ios(present, args.dry_run)

    print()
    if missing:
        print(f"Missing {len(missing)} of {len(slugs)} clip(s) in {ASSET_DIR.relative_to(ROOT)}:")
        for slug in missing:
            print(f"  - {slug}.mp3")
        print("Those hours stay on the silent hourly channel until the file lands.")
        print("See assets/audio/adhan/ZIKR_SOUNDS.md for the requirements.\n")

    if changed and not args.dry_run:
        print("Native resources changed — rebuild both apps (a hot restart won't pick them up).")
    elif not changed:
        print("Everything already in sync.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
