#!/usr/bin/env python3
"""
Validate minimal portable QGIS runtime layout.

This small script checks for the presence of a short list of files and
directories that are required for the portable runtime to launch. It's
intended as a quick unit-test-like check for CI or for a developer who
copied the tree and wants to ensure generated wrappers and application
binaries are present.

Exit codes:
 - 0: all checks passed
 - 1: at least one required file/dir missing

Example:
  python tools/validate_runtime.py

You can set the environment variable QGIS_ROOT to point to a different
installation root (defaults to the script's parent directory).
"""

from pathlib import Path
import os
import sys

# Quick contract: inputs/outputs
# - Input: optional QGIS_ROOT env var or use repo root (one level up from this script)
# - Output: printed report; exit code 0 on success, 1 on failure

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = Path(os.environ.get("QGIS_ROOT", SCRIPT_DIR.parent))

# Minimal required items to verify a functional runtime for launching QGIS
REQUIRED = [
    REPO_ROOT / 'bin' / 'qgis.bat',
    REPO_ROOT / 'bin' / 'qgis-bin.exe',
    REPO_ROOT / 'apps' / 'qgis' / 'bin' / 'qgis_app.dll',
    REPO_ROOT / 'etc' / 'ini',
    REPO_ROOT / 'Profiles',
]

OPTIONAL = [
    REPO_ROOT / 'bin' / 'textreplace.exe',
    REPO_ROOT / 'bin' / 'setup.bat',
    REPO_ROOT / 'etc' / 'postinstall' / 'setup.bat',
]

missing = []
print(f"Validating minimal QGIS runtime under: {REPO_ROOT}")
for p in REQUIRED:
    if not p.exists():
        print(f"MISSING: {p}")
        missing.append(p)
    else:
        print(f"OK:      {p}")

print("")
print("Optional files (helpful but not required):")
for p in OPTIONAL:
    print(f"{'OK:' if p.exists() else ' - :'} {p}")

if missing:
    print("\nRESULT: MISSING required files/dirs. See list above.")
    sys.exit(1)
else:
    print("\nRESULT: All required files present.")
    sys.exit(0)
