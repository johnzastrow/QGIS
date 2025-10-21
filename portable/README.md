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


  📋 Detailed Differences

  1. User Experience During Execution

  bin/reinit.bat (Interactive & Verbose):
  === QGIS portable reinitializer ===
  Repository root: D:\newQGIS
  Log: D:\newQGIS\var\log\reinit-2025-10-20_14-30-15.log
  Latest: D:\newQGIS\var\log\reinit-latest.log
  Repository root: D:\newQGIS
  Running textreplace to update templates...
  textreplace completed successfully
  Calling bin\setup.bat to finish setup...
  Running qgis postinstall wrapper (qgis.bat --postinstall)...
  OK: apps\qgis\bin\qgis_app.dll exists
  OK: bin\qgis-bin.env exists
  === Reinitialization complete ===

  portable/reinit_portable.bat (Silent):
  Reinit finished. See var\log\reinit-latest.log for summary and var\log\reinit-2025-10-20_143015.log for details.

  Impact: bin/reinit.bat provides real-time progress feedback, making it easier to diagnose where failures occur.
  portable/reinit_portable.bat requires checking logs.

  ---
  2. Timestamp Generation Method

  bin/reinit.bat - Simple string replacement:
  set "datetime=%DATE%_%TIME%"
  set "datetime=%datetime:/=-%"
  set "datetime=%datetime::=-%"
  set "datetime=%datetime: =_%"
  set "datetime=%datetime:,=-%"
  set "datetime=%datetime:.=-%"
  Result: reinit-Mon_10-20-2025__6-21-20-76.log (varies by locale)

  portable/reinit_portable.bat - Token parsing with padding:
  for /f "tokens=1-4 delims=/ .: " %%a in ("%date% %time%") do (
      set "Y=%%d"
      set "M=00%%b"
      set "D=00%%c"
      set "T=%%e"
  )
  set "M=%M:~-2%"
  set "D=%D:~-2%"
  set "TS=%Y%-%M%-%D%_%T%"
  Result: reinit-2025-10-20_06-21-20.log (more consistent format)

  Impact: portable/reinit_portable.bat has cleaner timestamp format, but both work.

  ---
  3. Validation Checks

  bin/reinit.bat:
  REM Check 1: Core DLL
  if exist "%REPO_ROOT%\apps\qgis\bin\qgis_app.dll" (
    call :log "OK: apps\qgis\bin\qgis_app.dll exists"
  ) else (
    call :log "WARNING: apps\qgis\bin\qgis_app.dll not found..."
  )

  REM Check 2: Generated environment file
  if exist "%REPO_ROOT%\bin\qgis-bin.env" (
    call :log "OK: bin\qgis-bin.env exists"
  ) else (
    call :log "WARNING: bin\qgis-bin.env not created..."
  )

  portable/reinit_portable.bat:
  REM Only checks qgis_app.dll
  if exist "apps\qgis\bin\qgis_app.dll" (
      echo OK: qgis_app.dll present >> "%LOG%"
  ) else (
      echo WARNING: qgis_app.dll missing >> "%LOG%"
  )

  Impact: bin/reinit.bat has more thorough validation - catches cases where setup ran but didn't create
  qgis-bin.env.

  ---
  4. Path Construction

  bin/reinit.bat - Absolute paths with quotes:
  "%REPO_ROOT%\bin\textreplace.exe" -std -t bin\setup.bat
  call "%REPO_ROOT%\bin\setup.bat"
  call "%REPO_ROOT%\bin\qgis.bat" --postinstall

  portable/reinit_portable.bat - Relative paths:
  bin\textreplace.exe -std -t bin\setup.bat
  call "bin\setup.bat"
  call "bin\qgis.bat" --postinstall

  Impact: bin/reinit.bat is more robust - works even if current directory changes. portable/reinit_portable.bat
  assumes pushd "%REPO_ROOT%" keeps context (which it does via pushd).

  ---
  ✅ Is portable/reinit_portable.bat Suitable for Updating a Moved Installation?

  Answer: YES ✅ It is functionally suitable, with caveats:

  Strengths:

  1. ✅ Performs all required operations: textreplace → setup → qgis postinstall
  2. ✅ Handles missing files gracefully: Falls back to etc\postinstall\setup.bat
  3. ✅ Creates proper logs: Both timestamped and latest
  4. ✅ Shorter and simpler: 43 lines less code
  5. ✅ Cleaner timestamp format: More predictable log filenames
  6. ✅ Self-contained: Doesn't rely on external functions

  Weaknesses:

  1. ❌ No user feedback during execution: Silent until completion (frustrating for interactive use)
  2. ❌ Less validation: Doesn't check if bin\qgis-bin.env was created
  3. ❌ No progress indication: User doesn't know if script is hung or working
  4. ❌ Less helpful error messages: Requires reading logs to understand failures

  ---
  🎯 Recommendations

  Use portable/reinit_portable.bat when:

  - ✅ Running automated/scripted deployments
  - ✅ Embedding in installers or deployment tools
  - ✅ You want simpler, more maintainable code
  - ✅ Log file inspection is part of your workflow

  Use bin/reinit.bat when:

  - ✅ Running interactively (by end users)
  - ✅ Troubleshooting issues (real-time feedback helps)
  - ✅ Need thorough validation (checks both DLL and env file)
  - ✅ Want user-friendly progress updates

  ---
  🔧 Testing Both Scripts on newQGIS

  To validate both scripts work correctly on newQGIS:

  REM Test 1: Using portable/reinit_portable.bat
  cd /d C:\Users\br8kw\Downloads\newQGIS
  portable\reinit_portable.bat
  type var\log\reinit-latest.log

  REM Test 2: Copy bin/reinit.bat to newQGIS and run
  copy ..\QGIS_orig\bin\reinit.bat bin\
  bin\reinit.bat

  REM Compare results
  fc bin\qgis-bin.env ..\QGIS_orig\bin\qgis-bin.env

  ---
  📝 Suggested Enhancement

  To get the best of both worlds, I'd recommend enhancing portable/reinit_portable.bat with minimal console output:

  REM Add after line 28:
  echo Reinitializing QGIS tree at %REPO_ROOT%
  echo [1/4] Running textreplace...
  REM ... existing textreplace code ...
  echo [2/4] Running setup scripts...
  REM ... existing setup code ...
  echo [3/4] Running QGIS postinstall...
  REM ... existing qgis.bat code ...
  echo [4/4] Validating installation...
  REM ... existing validation code ...
  echo Complete! See logs for details.

  This would provide progress feedback while keeping the script simple and portable.

  ---
  ✅ Final Verdict

  Both scripts are functionally equivalent and suitable for reinitializing a moved QGIS installation.

  - portable/reinit_portable.bat: ✅ Suitable - simpler, automated-friendly, but silent
  - bin/reinit.bat: ✅ Preferred - same functionality + better UX + thorough validation

  For newQGIS, either script will work. I'd recommend using bin/reinit.bat for its superior user feedback and
  validation, unless you're automating the process.