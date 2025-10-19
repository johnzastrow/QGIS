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
REM Parse args for non-interactive flags
set "AUTO_YES=0"
if not "%~1"=="" (
    for %%A in (%*) do (
        if /I "%%~A"=="--yes" set "AUTO_YES=1"
        if /I "%%~A"=="-y" set "AUTO_YES=1"
    )
)

REM Bootstrap the OSGeo4W environment directly by calling the local
REM `bin\o4w_env.bat`. Calling `OSGeo4W.bat` without parameters opens a
REM subshell (it runs `cmd /k`), which prevents the remainder of this
REM script from executing. Use the environment helper directly instead.
call "%~dp0\bin\o4w_env.bat"
if %ERRORLEVEL% neq 0 (
    echo Failed to set up OSGeo4W environment.
    exit /b %ERRORLEVEL%
) else (
    echo OSGeo4W environment set up successfully.
)

REM --- sanity checks: ensure apps\qgis\bin is available and qgis_app.dll exists
set QGIS_BIN_DIR=%OSGEO4W_ROOT%\apps\qgis\bin
if not exist "%QGIS_BIN_DIR%\qgis_app.dll" (
    REM If the main QGIS DLL is missing the runtime will fail with opaque
    REM loader errors. Detect this early and offer to (re)run the reinit
    REM helper which patches templates and recreates wrapper env files.
    echo ERROR: required DLL not found: "%QGIS_BIN_DIR%\qgis_app.dll"
    echo This usually means the generated templates/wrappers were not
    echo patched for this location (common when the tree was copied).
    if "%AUTO_YES%"=="1" (
        set "_ans=Y"
    ) else (
        echo Would you like to run "bin\\reinit.bat" now to attempt to fix this (Y/N)?
        set /p _ans=Choice: 
    )
    if /I "%_ans%"=="Y" (
        if exist "%~dp0bin\reinit.bat" (
            REM Run the reinit helper which will run textreplace and setup.
            echo Running bin\reinit.bat ...
            call "%~dp0bin\reinit.bat"
            echo Reinit complete; retrying launch...
        ) else (
            echo reinit.bat not found at "%~dp0bin\reinit.bat". Please run it manually from the repo root.
            exit /b 1
        )
    ) else (
        echo Aborting launch. Run "bin\\reinit.bat" to fix paths and try again.
        exit /b 1
    )
    REM After reinit attempt, verify DLL again
    if not exist "%QGIS_BIN_DIR%\qgis_app.dll" (
        echo ERROR: qgis_app.dll still not found after reinit. Aborting.
        exit /b 1
    )
)

echo Checking PATH for qgis bin directory...
echo %PATH% | findstr /I /C:"%QGIS_BIN_DIR%" >nul
if errorlevel 1 (
    REM The wrapper `bin\qgis.bat` will add the right bin directory to PATH
    REM when launched, but if you invoke `qgis-bin.exe` directly from some
    REM shells you may get missing-DLL errors. The warning helps diagnose
    REM that situation and points to the reinit helper.
    echo WARNING: "%QGIS_BIN_DIR%" is not on PATH for this shell.
    echo The wrapper "bin\qgis.bat" will add it when called, but if you still see loader errors run "bin\\reinit.bat".
)

rem Launch QGIS with specific profile and project using the wrapper
rem `bin\qgis.bat` configures PATH/QT_PLUGIN_PATH and then starts the
rem real binary. Always prefer calling the wrapper when running from this
rem portable tree.
REM Launch via the provided wrapper to ensure all runtime environment vars
REM (QT_PLUGIN_PATH, QGIS_PREFIX_PATH, VSI_CACHE, etc.) are set in this
REM process before starting the actual `qgis-bin.exe`.
call "%~dp0\bin\qgis.bat" --profiles-path "%~dp0\Profiles" --profile "Viewer2" --project "geopackage:%~dp0\data.gpkg?projectName=main_project"

if %ERRORLEVEL% neq 0 (
    echo Failed to launch QGIS.
    exit /b %ERRORLEVEL%
)   else echo QGIS launched with custom profile and project.

bin\textreplace -std -t bin\setup.bat
call bin\setup.bat
call etc\postinstall\setup.bat
