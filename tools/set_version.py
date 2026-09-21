#!/usr/bin/env python3
"""Set or validate the addon release version.

The Camelot TOC is the single source of truth for the packaged addon version.

Usage:
  python3 tools/set_version.py 1.0.7
  python3 tools/set_version.py v1.0.7
  python3 tools/set_version.py --check v1.0.7
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOC = ROOT / "HandyNotes_ForeverInstances_Camelot.toc"
VERSION_RE = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")
TOC_VERSION_RE = re.compile(r"^## Version:\s*(.+?)\s*$", re.MULTILINE)


def normalize(raw: str) -> tuple[str, str]:
    value = raw.strip()
    match = VERSION_RE.fullmatch(value)
    if not match:
        raise ValueError(f"invalid release version: {raw!r}; expected X.Y.Z or vX.Y.Z")
    plain = ".".join(match.groups())
    return plain, f"v{plain}"


def read_version() -> str:
    text = TOC.read_text(encoding="utf-8")
    match = TOC_VERSION_RE.search(text)
    if not match:
        raise RuntimeError(f"missing ## Version in {TOC.name}")
    current, _ = normalize(match.group(1))
    return current


def write_version(version: str) -> None:
    text = TOC.read_text(encoding="utf-8")
    replacement = f"## Version: v{version}"
    updated, count = TOC_VERSION_RE.subn(replacement, text, count=1)
    if count != 1:
        raise RuntimeError(f"could not update ## Version in {TOC.name}")
    TOC.write_text(updated, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    try:
        expected, tag = normalize(args.version)
        current = read_version()
    except (ValueError, RuntimeError) as exc:
        print(exc, file=sys.stderr)
        return 2

    if args.check:
        if current != expected:
            print(f"version mismatch: TOC={current} expected={expected} ({tag})", file=sys.stderr)
            return 1
        print(f"Version OK: {tag}")
        return 0

    if current == expected:
        print(f"Version already set: {tag}")
        return 0

    write_version(expected)
    print(f"Updated {TOC.name}: v{current} -> {tag}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
