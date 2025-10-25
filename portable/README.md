# Portable QGIS Reinitialization Tools

This directory contains tools to reinitialize a portable QGIS installation after copying it to a new location or computer.

## Table of Contents

- [Why This Is Needed](#why-this-is-needed)
- [Available Scripts](#available-scripts)
- [Quick Start](#quick-start)
- [Detailed Usage](#detailed-usage)
- [What Gets Updated](#what-gets-updated)
- [Validation Checks](#validation-checks)
- [Troubleshooting](#troubleshooting)
- [Technical Details](#technical-details)

---

## Why This Is Needed

OSGeo4W-style portable QGIS installations contain **generated files that embed absolute paths** to the installation directory. These files are created during the initial installation and include:

- `bin\setup.bat` - Generated setup script with hardcoded paths
- `bin\qgis-bin.env` - Environment file with PATH, PYTHONHOME, QT_PLUGIN_PATH, etc.
- `apps\Python312\Scripts\*.py` - Python scripts with shebang lines pointing to the Python interpreter
- `apps\qgis\bin\qgis.reg` - Registry file with file association paths

**When you copy the QGIS tree to a new location**, these files still reference the **old path**, causing failures such as:
- ❌ `qgis_app.dll not found` errors
- ❌ Python scripts fail to execute
- ❌ Missing DLL errors when launching QGIS

The reinit scripts in this directory **regenerate all these files** with the correct paths for the new location.

---

## Available Scripts

This directory provides **two reinit scripts** with identical functionality but different user experiences:

### `interactive_reinit.bat` - Interactive Mode ✨

**Best for**: Manual/interactive use by end users

**Features**:
- ✅ Real-time console progress updates
- ✅ Shows what's happening at each step
- ✅ Displays validation results immediately
- ✅ Provides helpful reminders on how to launch QGIS
- ✅ Comprehensive logging to `var\log\reinit-interactive-*.log`

**Console Output Example**:
```
=== QGIS portable reinitializer (INTERACTIVE) ===
Repository root: D:\PortableQGIS
[Step 1/4] Running textreplace to update templates...
SUCCESS: textreplace completed successfully
[Step 2/4] Calling bin\setup.bat to finish setup...
SUCCESS: bin\setup.bat completed
...
```

### `silent_reinit.bat` - Silent Mode 🤫

**Best for**: Automated deployments, scripts, installers

**Features**:
- ✅ Completely silent operation (no console spam)
- ✅ Only shows final status message
- ✅ Identical functionality to interactive mode
- ✅ Comprehensive logging to `var\log\reinit-silent-*.log`
- ✅ Returns proper exit codes for automation

**Console Output Example**:
```
Reinitialization complete. See var\log\reinit-silent-latest.log for details.
```

---

## Quick Start - INSTRUCTIONS ARE OLD. I need to update them 10/24.

### Step 1: Copy the `portable/` Directory

When you copy your QGIS installation to a new location, make sure the `portable/` directory is included in the copy.

### Step 2: Run a Reinit Script

Open Command Prompt in the QGIS root directory and run:

**For interactive feedback** (recommended for manual use):
```bat
portable\interactive_reinit.bat
```

**For silent operation** (recommended for automation):
```bat
portable\silent_reinit.bat
```

### Step 3: Launch QGIS

After reinitialization completes successfully, launch QGIS using the wrapper:

```bat
bin\qgis.bat
```

⚠️ **Important**: Always use `bin\qgis.bat`, **NOT** `bin\qgis-bin.exe` directly!

---

## Detailed Usage

### Running from the QGIS Directory

```bat
REM Navigate to the copied QGIS installation
cd /d D:\PortableApps\QGIS

REM Run interactive reinit
portable\interactive_reinit.bat

REM Check the results
type var\log\reinit-interactive-latest.log

REM Launch QGIS
bin\qgis.bat
```

### Running from Anywhere

```bat
REM Run with absolute path
"D:\PortableApps\QGIS\portable\interactive_reinit.bat"

REM Launch QGIS with absolute path
"D:\PortableApps\QGIS\bin\qgis.bat"
```

### Automated Deployment Example

```bat
@echo off
REM deploy_qgis.bat - Automated QGIS deployment script

set "SOURCE=\\server\share\QGIS_Template"
set "TARGET=C:\Apps\QGIS"

echo Copying QGIS installation...
xcopy /E /I /H /K /Q "%SOURCE%" "%TARGET%"

echo Reinitializing QGIS at new location...
cd /d "%TARGET%"
call portable\silent_reinit.bat

if %ERRORLEVEL% equ 0 (
    echo Deployment successful!
    echo Launch QGIS with: "%TARGET%\bin\qgis.bat"
) else (
    echo Deployment failed with %ERRORLEVEL% errors.
    echo Check log: "%TARGET%\var\log\reinit-silent-latest.log"
    exit /b %ERRORLEVEL%
)
```

---

## What Gets Updated

The reinit scripts perform these operations in sequence:

### [Step 1/4] Template Regeneration

**Action**: Runs `bin\textreplace.exe -std -t bin\setup.bat`

**Purpose**: Regenerates `bin\setup.bat` from templates, embedding the new absolute path

**Input**: Template files (`.tmpl`) in `apps\Python312\Scripts\`, `setup\`, etc.

**Output**: `bin\setup.bat` with current installation path

### [Step 2/4] Setup Execution

**Action**: Calls `bin\setup.bat` (or falls back to `etc\postinstall\setup.bat`)

**Purpose**: Runs per-install setup actions to create environment files

**Output**:
- `bin\qgis-bin.env` - Environment variables file
- Updated Python script shebangs
- Registry file generation
- Cleanup of old `.pyc` files

### [Step 3/4] QGIS Postinstall

**Action**: Calls `bin\qgis.bat --postinstall`

**Purpose**: Finalizes QGIS-specific wrapper configuration

**Output**:
- Updated `apps\qgis\bin\qgis.reg` with correct paths
- Registered file associations (optional)

### [Step 4/4] Validation

**Action**: Checks for presence of critical files

**Purpose**: Ensures the reinitialization completed successfully

**Checks**: See [Validation Checks](#validation-checks) section below

---

## Validation Checks

Both scripts perform **8 comprehensive validation checks**:

| # | Check | Type | What It Validates |
|---|-------|------|-------------------|
| 1 | `apps\qgis\bin\qgis_app.dll` | **ERROR** | Core QGIS library present |
| 2 | `bin\qgis-bin.env` | WARNING | Environment file created |
| 3 | `bin\setup.bat` | WARNING | Setup script generated |
| 4 | `bin\qgis.bat` | **ERROR** | QGIS wrapper present |
| 5 | `apps\Python312\python.exe` | **ERROR** | Python runtime present |
| 6 | `apps\Python312\Scripts\gdal_calc.py` | WARNING | Sample Python script present |
| 7 | `etc\ini\gdal.bat` | **ERROR** | Environment init scripts present |
| 8 | `bin\o4w_env.bat` | **ERROR** | Environment bootstrap present |

**ERROR** = Critical failure, QGIS won't work
**WARNING** = Non-critical, but may indicate issues

### Exit Codes

The scripts return exit codes for automation:

- `0` - Success, all critical checks passed
- `1` - textreplace.exe failed
- `2` - No setup script found
- `>0` - Number of validation errors encountered

---

## Troubleshooting

### Problem: "textreplace.exe not found"

**Cause**: Some QGIS distributions don't include `bin\textreplace.exe`

**Solution**: The script will automatically fall back to `etc\postinstall\setup.bat`. This is normal and the reinitialization should still succeed.

### Problem: "qgis_app.dll not found" after reinit

**Symptoms**: Validation shows ERROR for `qgis_app.dll`

**Possible Causes**:
1. Incomplete copy - not all files were copied from source
2. Corrupted installation

**Solutions**:
1. Re-copy the entire QGIS directory from the original source
2. Verify the file exists: `dir apps\qgis\bin\qgis_app.dll`
3. Check the reinit log for details: `type var\log\reinit-*-latest.log`

### Problem: QGIS still fails to launch after reinit

**Symptoms**: Even after successful reinit, QGIS won't start

**Checklist**:
1. ✅ Are you using `bin\qgis.bat` (NOT `qgis-bin.exe`)?
2. ✅ Did reinit complete without errors? Check exit code and logs
3. ✅ Does `bin\qgis-bin.env` exist and contain the correct path?
4. ✅ Run validation manually:
   ```bat
   apps\Python312\python.exe tools\validate_runtime.py
   ```

### Problem: Python scripts fail with "python3.exe not found"

**Cause**: Python script shebangs still point to old location

**Check**:
```bat
head -1 apps\Python312\Scripts\gdal_calc.py
```
Should show current path like: `#! D:\PortableQGIS\apps\Python312\python3.exe`

**Solution**: Run reinit again to regenerate Python script shebangs

### Problem: Permission denied or access errors

**Cause**: Windows permissions or file locks

**Solutions**:
1. Run Command Prompt as Administrator
2. Close QGIS if it's running
3. Disable antivirus temporarily (some AV software blocks batch script operations)
4. Check if any files are marked read-only: `attrib /S`

---

## Technical Details

### Files Modified During Reinit

The following files are **regenerated** with updated paths:

**Always Modified**:
- `apps\Python312\Scripts\*.py` - Shebang lines updated
- `apps\qgis\bin\qgis.reg` - Registry paths updated

**Conditionally Modified** (depending on what `bin\setup.bat` does):
- `bin\qgis-bin.env` - May be created or updated
- `bin\setup.bat` - Regenerated from templates (if textreplace.exe exists)

### Files That DON'T Need Regeneration

These files use **dynamic path resolution** via `%OSGEO4W_ROOT%`:
- `etc\ini\*.bat` - All environment initialization scripts
- `bin\o4w_env.bat` - Computes OSGEO4W_ROOT at runtime
- `bin\qgis.bat` - Uses OSGEO4W_ROOT from o4w_env.bat

This is why the tree is **portable** - most files adapt automatically!

### Log File Locations

Both scripts write logs to `var\log\`:

**Interactive Mode**:
- `var\log\reinit-interactive-<timestamp>.log` - Full detailed log
- `var\log\reinit-interactive-latest.log` - Copy of most recent run

**Silent Mode**:
- `var\log\reinit-silent-<timestamp>.log` - Full detailed log
- `var\log\reinit-silent-latest.log` - Copy of most recent run

### Timestamp Format

Both scripts use consistent timestamp format: `YYYY-MM-DD_HHMMSS`

Example: `reinit-interactive-2025-10-20_143052.log`

---

## Safety Notes

- ✅ **Safe to run multiple times** - Rerunning reinit is harmless
- ✅ **Non-destructive** - Only modifies generated files, not core QGIS files
- ✅ **No system-wide changes** - Only affects files within the QGIS tree
- ✅ **Reversible** - Can always re-copy from original installation
- ⚠️ **Administrator rights** - May be required on some systems for registry operations

---

## Example Run  October 24, 2025

Note: Sadly, this simple script suggested by a QGIS maintainer produced no effect, and I couldn't see any debug information to see what was happening.

```
REM RunAtlas.bat
call "%~dp0\bin\qgis.bat" --postinstall
"%~dp0\bin\qgis.bat" --profiles-path "%~dp0\Profiles"  --profile "Viewer2" --project "geopackage:%~dp0\data.gpkg?projectName=main_project"
```


This is what a run of interactive_reinit.ps1 version 1.1.7 looked like and ultimately produced a running QGIS after copying it to another path, where initially it failed.

```bash
PS W:\deleteme\portable_installation> powershell -ExecutionPolicy Bypass -File .\interactive_reinit.ps1 -Debug
=== QGIS portable reinitializer (INTERACTIVE) v1.1.7 ===
Repository root: W:\deleteme
Log: W:\deleteme\var\log\reinit-interactive-2025-10-24_152459.log
Latest: W:\deleteme\var\log\reinit-interactive-latest.log

Script: portable\interactive_reinit.ps1 v1.1.7
Repository root: W:\deleteme
OSGEO4W_ROOT set to: W:\deleteme

[Step 1/4] Note: textreplace.exe not found in bin\ - skipping template replacement.

ERROR: No setup script found (bin\setup.bat or etc\postinstall\setup.bat). Cannot reinitialize automatically.
PS W:\deleteme\portable_installation> cd bin
PS W:\deleteme\portable_installation\bin> powershell -ExecutionPolicy Bypass -File .\interactive_reinit.ps1 -Debug
=== QGIS portable reinitializer (INTERACTIVE) v1.1.7 ===
Repository root: W:\deleteme\portable_installation
Log: W:\deleteme\portable_installation\var\log\reinit-interactive-2025-10-24_152610.log
Latest: W:\deleteme\portable_installation\var\log\reinit-interactive-latest.log

Script: portable\interactive_reinit.ps1 v1.1.7
Repository root: W:\deleteme\portable_installation
OSGEO4W_ROOT set to: W:\deleteme\portable_installation

[Step 1/4] Running textreplace to update templates...
  Debug: Attempting direct call to textreplace (PowerShell) first...
  Debug: calling textreplace directly: "W:\deleteme\portable_installation\bin\textreplace.exe" -std -t bin\setup.bat
  Debug: direct call returned exit 0 or indicated missing env; falling back to cmd.exe wrapper...
  Debug: cmd fallback command: set "OSGEO4W_ROOT=W:\deleteme\portable_installation" && set "OSGEO4W_ROOT_MSYS=W:/deleteme/portable_installation" && "W:\deleteme\portable_installation\bin\textreplace.exe" -std -t bin\\setup.bat
SUCCESS: textreplace completed successfully (cmd fallback)

[Step 2/4] bin\setup.bat would launch GUI installer (osgeo4w-setup.exe) or references it; skipping automatic run.
  To complete installation non-interactively, run RunQGIS.bat --yes or use the -y flag where supported.
  Alternatively, run the installer interactively: W:\deleteme\portable_installation\bin\osgeo4w-setup.exe

[Step 2.5] Ensure bin\qgis-bin.env matches this tree (backup + update)...
  Backed up existing qgis-bin.env to: W:\deleteme\portable_installation\bin\qgis-bin.env.bak-2025-10-24_152610
  Debug: textreplace available, attempting to regenerate env via textreplace...
  Debug: textreplace did not produce env; falling back to safe replace

[Step 3/4] Running qgis postinstall wrapper (qgis.bat --postinstall)...
SUCCESS: qgis postinstall completed

[Step 4/4] Validating installation integrity...
  [OK] apps\qgis\bin\qgis_app.dll exists
  [OK] bin\qgis-bin.env exists
  [OK] bin\setup.bat exists
  [OK] bin\qgis.bat exists
  [OK] apps\Python312\python.exe exists
  [OK] apps\Python312\Scripts\gdal_calc.py exists
  [OK] etc\ini\gdal.bat exists
  [OK] bin\o4w_env.bat exists

=== Reinitialization complete - All critical checks passed ===

Reinitialization complete. Check above for any errors.
See W:\deleteme\portable_installation\var\log\reinit-interactive-latest.log for latest summary.

============================================================
IMPORTANT: How to launch QGIS from this location
============================================================

Always use the wrapper script (NOT qgis-bin.exe directly):
  W:\deleteme\portable_installation\bin\qgis.bat

Example launch commands:
  cd /d "W:\deleteme\portable_installation"
  bin\qgis.bat

Or from anywhere:
  "W:\deleteme\portable_installation\bin\qgis.bat"

DO NOT run qgis-bin.exe directly - it will fail with DLL errors!
The wrapper sets up the environment (PATH, PYTHONHOME, QT_PLUGIN_PATH, etc.)
============================================================

```





## Additional Resources

For more detailed information about the QGIS portable installation system:

- **POSTINSTALL.md** (in repository root) - Detailed documentation of the postinstall system
- **CLAUDE.md** (in repository root) - Developer guide for working with this repository
- **var\log\setup.log.full** - Original installation log showing what the installer did

---

## Authors & License

These portable reinit tools are designed to make QGIS portable installations truly portable and easy to deploy across multiple machines without requiring reinstallation.

**License**: Same as QGIS (GNU General Public License)

---

**Last Updated**: 2025-10-20
**Compatible with**: QGIS 3.44.x OSGeo4W portable installations
**Maintained by**: Repository contributors


