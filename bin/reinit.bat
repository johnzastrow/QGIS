@echo off
REM reinit.bat - Reinitialize this portable QGIS tree after copying to a new path
REM
REM Background: the OSGeo4W/QGIS portable tree writes several generated
REM wrapper and environment files at install time. Those files often embed
REM absolute paths. When the tree is copied to a new location the generated
REM files may point to the old path and QGIS will fail to load with DLL
REM loader errors (e.g. "qgis_app.dll not found"). This helper attempts to
REM re-run the template patching and postinstall steps to recreate those
REM generated files for the current tree location.

setlocal enabledelayedexpansion

REM Resolve repo root (script is located in bin\; parent is repo root)
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fI"
pushd "%REPO_ROOT%"

REM Ensure the log directory exists. All activity is appended into a
REM timestamped file under var\log plus a stable reinit-latest.log for
REM quick inspection.
if not exist "%REPO_ROOT%\var\log" mkdir "%REPO_ROOT%\var\log"

REM Build a timestamp-safe log filename by sanitizing characters from date/time
set "datetime=%DATE%_%TIME%"
set "datetime=%datetime:/=-%"
set "datetime=%datetime::=-%"
set "datetime=%datetime: =_%"
set "datetime=%datetime:,=-%"
set "datetime=%datetime:.=-%"
set "LOG=%REPO_ROOT%\var\log\reinit-%datetime%.log"
set "LATESTLOG=%REPO_ROOT%\var\log\reinit-latest.log"

echo === QGIS portable reinitializer ===
echo Repository root: %REPO_ROOT%
echo Log: %LOG%
echo Latest: %LATESTLOG%

echo START: %DATE% %TIME% > "%LOG%"
echo START: %DATE% %TIME% > "%LATESTLOG%"

REM Log a little context for diagnostic purposes
call :log "Repository root: %REPO_ROOT%"

REM 1) Regenerate generated wrappers/templates using textreplace (if available)
REM This step will rewrite files such as bin\setup.bat from templates and is
REM the normal installer behavior that embeds correct absolute paths.
if exist "%REPO_ROOT%\bin\textreplace.exe" (
  call :log "Running textreplace to update templates..."
  "%REPO_ROOT%\bin\textreplace.exe" -std -t bin\setup.bat >> "%LOG%" 2>&1
  if errorlevel 1 (
    call :log "ERROR: textreplace failed (exit %ERRORLEVEL%). See log for details."
    popd
    endlocal
    exit /b 1
  ) else call :log "textreplace completed successfully"
) else (
  call :log "Note: textreplace.exe not found in bin\ - skipping template replacement."
)

REM 2) Run bin\setup.bat (preferred) or etc\postinstall\setup.bat as a fallback
REM The generated setup script will perform per-install actions (env files,
REM registry of resources, etc.). If it's not present we fall back to the
REM packaged postinstall script in etc\postinstall.
if exist "%REPO_ROOT%\bin\setup.bat" (
  call :log "Calling bin\setup.bat to finish setup..."
  call "%REPO_ROOT%\bin\setup.bat" >> "%LOG%" 2>&1
  if errorlevel 1 call :log "Warning: bin\setup.bat exited with error %ERRORLEVEL%"
  ) else if exist "%REPO_ROOT%\etc\postinstall\setup.bat" (
    call :log "bin\setup.bat not found; calling etc\postinstall\setup.bat instead..."
    call "%REPO_ROOT%\etc\postinstall\setup.bat" >> "%LOG%" 2>&1
    if errorlevel 1 call :log "Warning: etc\postinstall\setup.bat exited with error %ERRORLEVEL%"
  ) else (
    call :log "ERROR: No setup script found (bin\setup.bat or etc\postinstall\setup.bat). Cannot reinitialize automatically."
    popd
    endlocal
    exit /b 2
  )

REM 3) Run qgis postinstall actions (if any) to create env wrappers and register resources
REM Some distributions use the qgis wrapper with a --postinstall flag to
REM finalize runtime state; call it if present to ensure consistent wrappers.
if exist "%REPO_ROOT%\bin\qgis.bat" (
  call :log "Running qgis postinstall wrapper (qgis.bat --postinstall)..."
  call "%REPO_ROOT%\bin\qgis.bat" --postinstall >> "%LOG%" 2>&1
  if errorlevel 1 call :log "Warning: qgis postinstall returned %ERRORLEVEL%"
) else (
  call :log "Note: qgis.bat not present in bin\ - skipping qgis postinstall step."
)

REM 4) Basic checks - verify the expected generated files exist now
if exist "%REPO_ROOT%\apps\qgis\bin\qgis_app.dll" (
  call :log "OK: apps\qgis\bin\qgis_app.dll exists"
) else (
  call :log "WARNING: apps\qgis\bin\qgis_app.dll not found. Check that the QGIS application files were copied correctly."
)

if exist "%REPO_ROOT%\bin\qgis-bin.env" (
  call :log "OK: bin\qgis-bin.env exists"
) else (
  call :log "WARNING: bin\qgis-bin.env not created. You may need to rerun etc\postinstall\qgis.bat or reinstall."
)

call :log "=== Reinitialization complete ==="
echo END: %DATE% %TIME% >> "%LOG%"
echo END: %DATE% %TIME% >> "%LATESTLOG%"

REM ensure stable latest log contains the full timestamped log
copy /Y "%LOG%" "%LATESTLOG%" >nul 2>&1

popd
endlocal
exit /b 0

:log
rem log helper: echo to console and append to log
setlocal
set "_msg=%~1"
echo %_msg%
echo %_msg% >> "%LOG%"
echo %_msg% >> "%LATESTLOG%"
endlocal & goto :eof
