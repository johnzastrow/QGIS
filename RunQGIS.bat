REM RunQGIS.bat
@echo off
REM NOTE: Do NOT remove generated setup/env files here. Those files
REM (e.g. bin\setup.bat, bin\qgis-bin.env) are produced by the installer
REM postinstall step and by the generated wrapper scripts. Deleting them
REM here does not regenerate them and can leave the runtime without
REM necessary environment (PATH/QT_PLUGIN_PATH) so DLLs like
REM apps\qgis\bin\qgis_app.dll cannot be found.

REM If you copied this tree to a new path and need to reinitialize the
REM installation (rewrite absolute paths), run the postinstall/setup
REM reinitializer manually once (examples below). This script will only
REM set up the environment for the current shell and launch QGIS.
REM Example reinit commands (run from repository root):
REM   bin\textreplace -std -t bin\setup.bat
REM   call bin\setup.bat
REM or run the packaged postinstall:
REM   call etc\postinstall\setup.bat

REM Call OSGeo4W.bat to set up the environment
call "%~dp0\OSGeo4W.bat"
if %ERRORLEVEL% neq 0 (
    echo Failed to set up OSGeo4W environment.
    exit /b %ERRORLEVEL%
) else (
    echo OSGeo4W environment set up successfully.
)

REM --- sanity checks: ensure apps\qgis\bin is available and qgis_app.dll exists
set QGIS_BIN_DIR=%OSGEO4W_ROOT%\apps\qgis\bin
if not exist "%QGIS_BIN_DIR%\qgis_app.dll" (
    echo ERROR: required DLL not found: "%QGIS_BIN_DIR%\qgis_app.dll"
    echo This usually means the installation templates were not patched for this path.
    echo Run "bin\\reinit.bat" from the repository root to recreate generated wrappers and env files.
    exit /b 1
)

echo Checking PATH for qgis bin directory...
echo %PATH% | findstr /I /C:"%QGIS_BIN_DIR%" >nul
if errorlevel 1 (
    echo WARNING: "%QGIS_BIN_DIR%" is not on PATH for this shell.
    echo The wrapper "bin\qgis.bat" will add it when called, but if you still see loader errors run "bin\\reinit.bat".
)

rem Launch QGIS with specific profile and project using the wrapper
rem `bin\qgis.bat` configures PATH/QT_PLUGIN_PATH and then starts the
rem real binary. Always prefer calling the wrapper when running from this
rem portable tree.
call "%~dp0\bin\qgis.bat" --profiles-path "%~dp0\Profiles" --profile "Viewer2" --project "geopackage:%~dp0\data.gpkg?projectName=main_project"

if %ERRORLEVEL% neq 0 (
    echo Failed to launch QGIS.
    exit /b %ERRORLEVEL%
)   else echo QGIS launched with custom profile and project.

bin\textreplace -std -t bin\setup.bat
call bin\setup.bat
call etc\postinstall\setup.bat
