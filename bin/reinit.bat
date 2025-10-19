@echo off
REM reinit.bat - small helper to reinitialize a copied OSGeo4W/QGIS tree
REM Usage: run from repository root (or double-click). It will patch templates
REM and run the setup reinitializer so absolute paths are updated for this copy.

setlocal enabledelayedexpansion

REM resolve script dir and repo root
pushd %~dp0
cd ..
set OSGEO4W_ROOT=%CD%

echo Reinitializing OSGeo4W/QGIS tree at %OSGEO4W_ROOT%

REM 1) Patch templates (textreplace must exist in bin/)
if exist "%OSGEO4W_ROOT%\bin\textreplace.exe" (
    echo Running textreplace to patch templates...
    "%OSGEO4W_ROOT%\bin\textreplace" -std -t "bin\setup.bat" || echo textreplace returned non-zero
) else (
    echo textreplace.exe not found in bin\. Skipping template patch.
)

REM 2) Run generated setup if present
if exist "%OSGEO4W_ROOT%\bin\setup.bat" (
    echo Calling generated bin\setup.bat to finish reinitialization...
    call "%OSGEO4W_ROOT%\bin\setup.bat"
    echo setup.bat completed.
) else (
    echo bin\setup.bat not found. You can run 'call etc\postinstall\setup.bat' instead.
)

REM 3) Optional: call qgis.bat --postinstall to run qgis-specific postinstall steps
if exist "%OSGEO4W_ROOT%\bin\qgis.bat" (
    echo Running qgis postinstall (optional)...
    call "%OSGEO4W_ROOT%\bin\qgis.bat" --postinstall || echo qgis postinstall returned non-zero
)

echo Reinit finished. Try launching with bin\qgis.bat or RunQGIS.bat
popd
endlocal
@echo off
rem reinit.bat - Reinitialize this portable QGIS tree after copying to a new path
rem Usage: run from any cmd.exe. The script will operate relative to its location (bin\reinit.bat).

setlocal
REM Resolve repo root (one directory up from this script)
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fI"
pushd "%REPO_ROOT%"

echo === QGIS portable reinitializer ===
echo Repository root: %REPO_ROOT%

REM 1) Regenerate generated wrappers/templates using textreplace (if available)
if exist "%REPO_ROOT%\bin\textreplace.exe" (
  echo Running textreplace to update templates...
  "%REPO_ROOT%\bin\textreplace.exe" -std -t bin\setup.bat
  if errorlevel 1 (
    echo ERROR: textreplace failed.
    popd
    endlocal
    exit /b 1
  )
) else (
  echo Note: textreplace.exe not found in bin\ - skipping template replacement.
)

REM 2) Run bin\setup.bat (preferred) or etc\postinstall\setup.bat as fallback
if exist "%REPO_ROOT%\bin\setup.bat" (
  echo Calling bin\setup.bat to finish setup...
  call "%REPO_ROOT%\bin\setup.bat"
  if errorlevel 1 echo Warning: bin\setup.bat exited with error %ERRORLEVEL%
) else if exist "%REPO_ROOT%\etc\postinstall\setup.bat" (
  echo bin\setup.bat not found; calling etc\postinstall\setup.bat instead...
  call "%REPO_ROOT%\etc\postinstall\setup.bat"
  if errorlevel 1 echo Warning: etc\postinstall\setup.bat exited with error %ERRORLEVEL%
) else (
  echo ERROR: No setup script found (bin\setup.bat or etc\postinstall\setup.bat). Cannot reinitialize automatically.
  popd
  endlocal
  exit /b 2
)

REM 3) Run qgis postinstall actions (if any) to create env wrappers and register resources
if exist "%REPO_ROOT%\bin\qgis.bat" (
  echo Running qgis postinstall wrapper (qgis.bat --postinstall)...
  call "%REPO_ROOT%\bin\qgis.bat" --postinstall
  if errorlevel 1 echo Warning: qgis postinstall returned %ERRORLEVEL%
) else (
  echo Note: qgis.bat not present in bin\ - skipping qgis postinstall step.
)

REM 4) Basic checks
if exist "%REPO_ROOT%\apps\qgis\bin\qgis_app.dll" (
  echo OK: apps\qgis\bin\qgis_app.dll exists
) else (
  echo WARNING: apps\qgis\bin\qgis_app.dll not found. Check that the QGIS application files were copied correctly.
)

if exist "%REPO_ROOT%\bin\qgis-bin.env" (
  echo OK: bin\qgis-bin.env exists
) else (
  echo WARNING: bin\qgis-bin.env not created. You may need to rerun etc\postinstall\qgis.bat or reinstall.
)

echo === Reinitialization complete ===
popd
endlocal
exit /b 0
