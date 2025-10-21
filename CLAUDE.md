# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an OSGeo4W-style portable QGIS distribution tree for Windows. The repository contains a full, self-contained QGIS installation with its own Python runtime, Qt libraries, GDAL/PROJ dependencies, and runtime environment setup scripts. The tree is designed to be portable (can be copied to new locations) but requires reinitialization after moving.

## Key Architecture Concepts

### Environment Bootstrap System

QGIS relies on a multi-stage environment setup:

1. **`bin/o4w_env.bat`** - Core environment bootstrapper that:
   - Sets `OSGEO4W_ROOT` to the installation directory
   - Resets PATH to a clean slate
   - Sources all `etc/ini/*.bat` files to set runtime environment variables

2. **`etc/ini/*.bat` files** - Environment modules that set critical paths:
   - `gdal.bat` - Sets `GDAL_DATA`, `GDAL_DRIVER_PATH`
   - `python3.bat` - Sets `PYTHONHOME`, `PYTHONPATH`, `PYTHONUTF8`
   - `qt5.bat` - Sets `QT_PLUGIN_PATH` and Qt-related paths
   - `proj-runtime-data.bat` - Sets `PROJ_DATA`
   - `openssl.bat` - Sets SSL certificate paths

3. **`bin/qgis.bat`** - Application wrapper that:
   - Calls `o4w_env.bat` to set base environment
   - Adds GRASS support paths if available
   - Sets QGIS-specific variables (`QGIS_PREFIX_PATH`, `VSI_CACHE`, etc.)
   - Launches `qgis-bin.exe`

### Postinstall/Template System

The tree uses a template patching system to embed absolute paths:

- **`bin/textreplace.exe`** - Patches template files (`.tpl`) to generate scripts with absolute paths
- **`bin/setup.bat`** (generated) - Main postinstall script that creates:
  - `bin/qgis-bin.env` - Environment file consumed by wrappers
  - Various wrapper scripts under `apps/Python312/Scripts/`
- **`etc/postinstall/*.bat.done`** - Historical record of postinstall commands that ran during packaging

**Critical**: When the tree is copied to a new location, generated files still reference the old path. Run `bin/reinit.bat` to regenerate them.

### Directory Structure

- **`apps/qgis/`** - Core QGIS application
  - `bin/` - QGIS DLLs and executables (qgis_app.dll is the main library)
  - `python/` - PyQGIS packages and libraries
  - `plugins/` - QGIS plugins
  - `qtplugins/` - Qt plugins specific to QGIS
  - `doc/` - Documentation including INSTALL.md

- **`apps/Python312/`** - Bundled Python 3.12 runtime
  - `Scripts/` - Python CLI wrappers (GDAL tools, PyQt5 tools, etc.)

- **`bin/`** - Executables and wrappers
  - `qgis-bin.exe` - Main QGIS executable
  - `qgis.bat`, `python-qgis.bat`, `qgis_process-qgis.bat` - Wrappers
  - `o4w_env.bat` - Environment bootstrapper
  - `reinit.bat` - Reinitialization helper

- **`etc/`** - Configuration and setup scripts
  - `ini/` - Environment module scripts
  - `postinstall/` - Postinstall script records

- **`qgis/`** - Build system and source-related files
  - `CMakeLists.txt` - CMake configuration
  - `vcpkg/vcpkg.json` - Dependency manifest (GDAL, PROJ, Qt6, Python, Boost)
  - `apps.qgis.doc/INSTALL.md` - Detailed build instructions

## Common Commands

### Running QGIS

Launch QGIS with the workspace profile and sample project:
```bat
RunQGIS.bat
```

Non-interactive mode (auto-reinitialize if needed):
```bat
RunQGIS.bat --yes
```

Launch QGIS directly via wrapper:
```bat
call bin\qgis.bat
```

### Reinitialization After Moving Tree

After copying the tree to a new location, regenerate absolute path references:
```bat
bin\reinit.bat
```

This runs:
1. `textreplace.exe` to regenerate `bin/setup.bat` from templates
2. `bin/setup.bat` to create environment files
3. `bin/qgis.bat --postinstall` to finalize QGIS wrappers

### Validation

Check that required runtime files exist:
```bat
apps\Python312\python.exe tools\validate_runtime.py
```

Validate environment variables are set correctly:
```bat
call bin\o4w_env.bat && set GDAL_DATA && set PROJ_DATA && set PYTHONHOME && set QT_PLUGIN_PATH
```

### Building from Source (if CMake project present)

Configure build with Qt6:
```powershell
cmake -S qgis -B build -DBUILD_WITH_QT6=ON -DWITH_QTWEBKIT=OFF -DVCPKG_TARGET_TRIPLET=x64-windows-release
```

Build:
```powershell
cmake --build build --config Release
```

Enable and run tests:
```powershell
cmake -S qgis -B build -DENABLE_TESTS=TRUE
cmake --build build --config Release
cd build
ctest --show-only
```

## Important Conventions

### Environment Variable Precedence

The OSGeo4W system uses a strict environment setup order:
1. `OSGEO4W_ROOT` must be set first (points to repository root)
2. Base environment via `etc/ini/*.bat` modules
3. Application-specific overrides in wrappers like `bin/qgis.bat`

Never manually set `PATH`, `PYTHONHOME`, or `QT_PLUGIN_PATH` - use the wrappers.

### Wrapper vs Direct Execution

**Always** use wrappers (`bin/qgis.bat`, `bin/python-qgis.bat`) instead of calling executables directly:
- ❌ `bin\qgis-bin.exe` (will fail with DLL errors)
- ✅ `bin\qgis.bat` (sets environment, then launches qgis-bin.exe)

### Python Environment

The tree ships its own Python (3.12) under `apps/Python312/`. When adding Python code:
- Place PyQGIS packages under `apps/qgis/python/`
- Use `apps/Python312/python.exe` for consistency
- Python wrappers are generated during postinstall via `textreplace`

### Postinstall Modifications

Certain files are **generated** and should not be edited directly:
- `bin/setup.bat` (generated from templates)
- `bin/qgis-bin.env` (created by setup scripts)
- `apps/Python312/Scripts/*.exe` wrappers (created by textreplace)

If these need changes, modify the templates or postinstall scripts in `etc/postinstall/`.

## Diagnostic Workflow

When QGIS fails to launch:

1. **Check for qgis_app.dll**:
   ```bat
   dir apps\qgis\bin\qgis_app.dll
   ```
   If missing after copying tree, run `bin\reinit.bat`

2. **Verify environment variables**:
   ```bat
   call bin\o4w_env.bat
   echo %OSGEO4W_ROOT%
   echo %QT_PLUGIN_PATH%
   echo %GDAL_DATA%
   ```

3. **Check logs**:
   - `var/log/setup.log.full` - Full postinstall output
   - `var/log/reinit-latest.log` - Latest reinit run

4. **Run runtime validator**:
   ```bat
   apps\Python312\python.exe tools\validate_runtime.py
   ```

## Integration Points

### GDAL and PROJ

QGIS links to packaged GDAL and PROJ libraries:
- GDAL drivers: `apps/gdal/lib/gdalplugins`
- PROJ data grids: `share/proj`
- Environment controlled via `etc/ini/gdal.bat` and `etc/ini/proj-runtime-data.bat`

### Qt Plugins

Qt plugins are loaded from two locations (see `bin/qgis.bat`):
- `apps/qgis/qtplugins` (QGIS-specific Qt plugins)
- `apps/qt5/plugins` (standard Qt plugins)

Both must be in `QT_PLUGIN_PATH` for QGIS to launch.

### Build Dependencies (vcpkg)

`qgis/vcpkg/vcpkg.json` defines build dependencies:
- GDAL >= 3.2.0 (pinned to 3.4.0)
- PROJ >= 8.0.0
- Qt >= 6.0.0
- Python >= 3.12.0
- Boost >= 1.75.0

When modifying native dependencies, update this manifest.

## Files to Never Commit

- `bin/setup.bat` (generated)
- `bin/qgis-bin.env` (generated)
- `var/log/*.log` (runtime logs)
- Any `.pyc` files under `apps/qgis/python/`

## Tree Portability Notes

This tree is **semi-portable**:
- Can be copied to new locations
- **Must** run `bin/reinit.bat` after copying
- Some absolute paths are embedded in compiled binaries (cannot be patched)
- Non-interactive reinit: `RunQGIS.bat --yes` auto-runs reinit if needed
