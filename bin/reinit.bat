@echo off
REM reinit.bat - Reinitialize this portable QGIS tree after copying to a new path
REM This script logs actions to var\log\reinit-<timestamp>.log

setlocal enabledelayedexpansion

REM Resolve repo root (one directory up from this script)
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fI"
pushd "%REPO_ROOT%"

REM Ensure log directory exists
if not exist "%REPO_ROOT%\var\log" mkdir "%REPO_ROOT%\var\log"

REM Build a timestamp for the log file (sanitize characters)
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

echo === START: %DATE% %TIME% ===> "%LOG%" & echo === START: %DATE% %TIME% ===> "%LATESTLOG%"
echo START: %DATE% %TIME% > "%LOG%"
echo START: %DATE% %TIME% > "%LATESTLOG%"

REM Helper to log lines to console and file
  call :log "Repository root: %REPO_ROOT%"

REM 1) Regenerate generated wrappers/templates using textreplace (if available)
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

REM 2) Run bin\setup.bat (preferred) or etc\postinstall\setup.bat as fallback
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
if exist "%REPO_ROOT%\bin\qgis.bat" (
  call :log "Running qgis postinstall wrapper (qgis.bat --postinstall)..."
  call "%REPO_ROOT%\bin\qgis.bat" --postinstall >> "%LOG%" 2>&1
  if errorlevel 1 call :log "Warning: qgis postinstall returned %ERRORLEVEL%"
) else (
  call :log "Note: qgis.bat not present in bin\ - skipping qgis postinstall step."
)

REM 4) Basic checks
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
