## Quick agent guide — QGIS (OSGeo4W portable tree)

This repository is a full OSGeo4W-style QGIS distribution tree (Windows). Use this file to get immediately productive: big-picture, how to run/build, and project-specific conventions.

### Big picture (what lives where)
- Native C++ core + desktop: built with CMake. Main binaries live under `build/output/bin` when built or `bin/`/`apps/qgis/bin` in this workspace.
- Python runtime shipped inside `apps/Python312/` — Python packages for PyQGIS live under `apps/qgis/python`.
- Qt plugins and QGIS plugins: `apps/qgis/qtplugins` and `apps/qgis/plugins`.
- Packaging/installer: OSGeo4W packaging and runtime glue (scripts and .bat files) are under the repo root (e.g. `bin/`, `etc/`, `setup/`, `postinstall/`).

Key files to inspect first: `apps/qgis/doc/INSTALL.md` (detailed build notes), `bin/qgis.bat` (env wrapper), and `RunQGIS.bat` (how this workspace launches QGIS with a profile/project).

Small, useful runtime helpers you should know about:
- `bin/reinit.bat` — run this once after copying the tree to a new path. It runs `textreplace` (if present) and the packaged postinstall/setup to recreate generated wrapper/env files that embed absolute paths.
- `RunQGIS.bat --yes` / `RunQGIS.bat -y` — non-interactive flag to auto-run the `reinit` helper if the main QGIS DLL is missing (useful for scripted launches or CI).
- `tools/validate_runtime.py` and `tools/validate_runtime.ps1` — small validators that check a minimal set of files/dirs and return 0/1 for quick CI or local sanity checks.

### How to run right now (workspace-specific)
- This tree is designed to be launched via the OSGeo4W environment. The provided `RunQGIS.bat` does the correct setup: it calls `OSGeo4W.bat` then runs `bin\qgis-bin.exe` with a profile and a geopackage project example (`data.gpkg`). Use that to run the app without rebuilding.

Example (what `RunQGIS.bat` shows):
```
call "%~dp0\OSGeo4W.bat"
call "%~dp0\bin\qgis-bin.exe" --profiles-path "%~dp0\Profiles" --profile "Viewer2" --project "geopackage:%~dp0\data.gpkg?projectName=main_project"
```

`bin\qgis.bat` is a useful env-wrapper: it sets `QGIS_PREFIX_PATH`, `QT_PLUGIN_PATH`, `VSI_CACHE` and starts `qgis-bin.exe`. When writing patches that change runtime behavior, verify with that wrapper.

### Build & developer workflows (Windows-focused)
- QGIS uses CMake. Typical Windows flow (Developer PowerShell): configure with CMake, build with MSBuild or Ninja. The project supports vcpkg; the manifest is at `vcpkg/vcpkg.json`.
- Common CMake flags you will see/use: `WITH_QTWEBKIT`, `BUILD_WITH_QT6` (or `BUILD_WITH_QT6=ON`), `WITH_BINDINGS`, `WITH_SERVER`, `WITH_PYTHON`, `WITH_QGIS_PROCESS`, `ENABLE_TESTS`.
- Don't reuse Qt5 vs Qt6 build directories. Prefer empty out-of-source build dirs (ccmake/cmake -B build).

Example configure snippet (from INSTALL.md):
```
# Developer PowerShell / cmd (Windows)
cmake -S . -B build -DSDK_PATH="path/to/vcpkg-export" -DBUILD_WITH_QT6=ON -DWITH_QTWEBKIT=OFF -DVCPKG_TARGET_TRIPLET=x64-windows-release
cmake --build build --config Release
```

Test and debug
- Enable tests with `-D ENABLE_TESTS=TRUE` and run from the build dir: `ctest --show-only` or `make test` / `cmake --build . --target test` / `make Experimental` (uploads to CDash in upstream CI).
- For debug output use `-D CMAKE_BUILD_TYPE=Debug` or `RelWithDebInfo` to keep symbols.

### Project-specific conventions & gotchas
- OSGeo4W environment variables: many scripts expect `OSGEO4W_ROOT`. Use the `.bat` wrappers to set consistent envs rather than hand-editing PATH.
- Runtime tuning in `bin\qgis.bat`: `VSI_CACHE=TRUE` and `VSI_CACHE_SIZE` are set here — tests or memory-sensitive runs may rely on these.
- Python environment: the repo ships its own Python under `apps/Python312/`. When adding Python code, ensure it installs under that tree for runtime parity.
- Build outputs and installs are often configured into a local `apps/` prefix (see INSTALL.md examples using `-D CMAKE_INSTALL_PREFIX=${HOME}/apps` on *nix). On Windows prefer using an SDK/vcpkg or OSGeo4W packaging pipeline.

### Integration points
- GDAL/PROJ: QGIS links to system/packaged GDAL and PROJ. Use the OSGeo4W packages or vcpkg SDK to control versions — do not assume system defaults.
- OSGeo4W packaging: build recipes and packaging are done externally (see INSTALL.md references to OSGeo4W build recipes). If changing native deps, update `vcpkg/vcpkg.json` or OSGeo4W recipe as appropriate.
- qgis_process: a standalone CLI tool (CMake flag `WITH_QGIS_PROCESS`) used for headless processing — useful for CI and debugging processing scripts.

### Where to make changes (safe places for iterative edits)
- Small UI/logic changes: prefer to modify the C++ source and run a local build of `qgis_desktop`/`qgis` target.
- Python plugins or tooling: put under `apps/qgis/python` or `apps/qgis/plugins` and validate with the shipped Python interpreter.
- CI/packaging adjustments: update `vcpkg/` manifests or OSGeo4W packaging scripts under `setup/` and `postinstall/`.

### Quick reference (files & dirs)
- `apps/qgis/doc/INSTALL.md` — canonical build/run instructions
- `RunQGIS.bat`, `bin/qgis.bat` — how this workspace launches runtime and sets env
- `apps/Python312/` — shipped Python runtime
- `apps/qgis/python`, `apps/qgis/plugins` — PyQGIS and plugins
- `vcpkg/vcpkg.json` — pinned dependency manifest (when using vcpkg)

If anything here looks wrong or you want a deeper section (CI, debugging native crashes, or plugin development specifics), tell me which area to expand and I'll iterate.
