Portable helper files for reinitializing a copied QGIS tree
=======================================================

Purpose
-------
This `portable/` directory contains a minimal, self-contained helper set you
can copy into a fresh QGIS portable installation to repair the runtime after
moving the tree to a new path or machine.

Why this is needed
-------------------
OSGeo4W-style portable QGIS uses small generated wrapper and environment
files that embed absolute paths at install/postinstall time. When the tree is
copied to a different path these generated files still point at the original
path and the QGIS binary may fail to load with DLL lookup errors (for
example: "qgis_app.dll not found").

What these helpers do
---------------------
- `reinit_portable.bat` — attempts to recreate the generated files by running
  `bin\textreplace.exe` (if present) to rewrite `bin\setup.bat`, then
  calling the generated `bin\setup.bat` or falling back to
  `etc\postinstall\setup.bat`. It also runs `bin\qgis.bat --postinstall`
  if the wrapper exists. All output is written to `var\log\reinit-<ts>.log`
  and to `var\log\reinit-latest.log`.

How to use this directory
-------------------------

1. Copy the entire `portable/` directory into the root of the QGIS tree you
  moved (so there is now `...\QGIS\portable\reinit_portable.bat`).

1. Open an elevated Command Prompt in the QGIS root and run:

```bat
portable\reinit_portable.bat
```

1. When the script completes, check `var\log\reinit-latest.log` for a
  short summary and `var\log\reinit-<timestamp>.log` for the full
  output.

Safety and limitations

- The script is conservative: it prefers `bin\setup.bat` if generated, and
  falls back to packaged `etc\postinstall\setup.bat` only when necessary.

If something goes wrong

- If the script fails, copy the generated `var\log\reinit-<timestamp>.log` and
  attach it to an issue or support request so the exact command failure can be
  diagnosed.

Authors

- Small helper set created to make portable QGIS trees relocatable without
  rebuilding or reinstalling.

Safety and limitations
----------------------
- The script is conservative: it prefers `bin\setup.bat` if generated, and
  falls back to packaged `etc\postinstall\setup.bat` only when necessary.
- If `bin\textreplace.exe` is not present in your tree the script will skip
  template patching and rely on the postinstall fallback.
- This helper does not modify system-wide configuration; it only touches
  files under the QGIS tree.

If something goes wrong
-----------------------
If the script fails, copy the generated `var\log\reinit-<timestamp>.log` and
attach it to an issue or support request so the exact command failure can be
diagnosed.

Authors
-------
Small helper set created to make portable QGIS trees relocatable without
rebuilding or reinstalling.


Detailed Comparison: bin/reinit.bat vs portable/reinit_portable.bat

  📊 Feature-by-Feature Comparison

  | Feature           | bin/reinit.bat                            | portable/reinit_portable.bat  | Winner
     |
  |-------------------|-------------------------------------------|-------------------------------|-----------------
  ---|
  | Lines of code     | 123 lines                                 | 80 lines                      | Portable
  (simpler) |
  | Script location   | bin/ directory                            | portable/ directory           | -
     |
  | Root resolution   | SCRIPT_DIR/..\ (parent of bin)            | %~dp0..\ (parent of portable) | ✅ Equal
      |
  | Console output    | ✅ Rich: Header, progress updates, results | ❌ Minimal: Only final message | bin/reinit.bat
       |
  | User feedback     | ✅ Real-time via :log function             | ❌ Silent until completion     | bin/reinit.bat
       |
  | Logging           | ✅ Dual: timestamped + latest              | ✅ Dual: timestamped + latest  | ✅ Equal
        |
  | Error handling    | ✅ Verbose with context                    | ❌ Terse messages              | bin/reinit.bat
       |
  | Validation checks | ✅ 2 checks: qgis_app.dll + qgis-bin.env   | ❌ 1 check: qgis_app.dll only  | bin/reinit.bat
       |
  | Path safety       | ✅ Quoted: "%REPO_ROOT%\bin\..."           | ⚠️ Relative: bin\...          | bin/reinit.bat
      |
  | Exit codes        | ✅ Documented: 0, 1, 2                     | ✅ Same: 0, 1, 2               | ✅ Equal
        |

  ---
  🔍 Core Functional Sequence (Both Identical)

  Both scripts perform the exact same operations in the exact same order:

  flowchart TD
      START[Script starts] --> ROOT[Compute REPO_ROOT]
      ROOT --> MKDIR[Create var/log if needed]
      MKDIR --> TR_CHECK{textreplace.exe<br/>exists?}

      TR_CHECK -->|Yes| TR[Run: bin\textreplace.exe -std -t bin\setup.bat]
      TR_CHECK -->|No| SKIP_TR[Skip textreplace]

      TR --> SETUP_CHECK
      SKIP_TR --> SETUP_CHECK

      SETUP_CHECK{bin\setup.bat<br/>exists?}
      SETUP_CHECK -->|Yes| RUN_SETUP[Call: bin\setup.bat]
      SETUP_CHECK -->|No| FALLBACK{etc\postinstall\setup.bat<br/>exists?}

      FALLBACK -->|Yes| RUN_FALLBACK[Call: etc\postinstall\setup.bat]
      FALLBACK -->|No| ERROR[EXIT 2: No setup script]

      RUN_SETUP --> QW_CHECK
      RUN_FALLBACK --> QW_CHECK

      QW_CHECK{bin\qgis.bat<br/>exists?}
      QW_CHECK -->|Yes| RUN_QW[Call: bin\qgis.bat --postinstall]
      QW_CHECK -->|No| SKIP_QW[Skip qgis postinstall]

      RUN_QW --> VALIDATE
      SKIP_QW --> VALIDATE

      VALIDATE[Validate qgis_app.dll exists]
      VALIDATE --> SUCCESS[EXIT 0: Success]

      style TR fill:#fff4e1
      style RUN_SETUP fill:#e1f5ff
      style RUN_FALLBACK fill:#e1f5ff
      style RUN_QW fill:#e1f5ff
      style SUCCESS fill:#d4edda
      style ERROR fill:#f8d7da

  Verdict: ✅ Core functionality is 100% identical