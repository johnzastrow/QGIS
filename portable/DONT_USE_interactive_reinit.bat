@echo off
REM interactive_reinit.bat - Reinitialize this portable QGIS tree after copying to a new path
REM
REM Background: the OSGeo4W/QGIS portable tree writes several generated
REM wrapper and environment files at install time. Those files often embed
REM absolute paths. When the tree is copied to a new location the generated
REM files may point to the old path and QGIS will fail to load with DLL
REM loader errors (e.g. "qgis_app.dll not found"). This helper attempts to
REM re-run the template patching and postinstall steps to recreate those
REM generated files for the current tree location.
REM
REM This is the INTERACTIVE version that provides real-time console feedback.
REM For automated/silent operation, use silent_reinit.bat instead.

setlocal enabledelayedexpansion

REM Resolve repo root (script is located in portable\; parent is repo root)
for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
pushd "%REPO_ROOT%"

REM Set OSGEO4W_ROOT early so textreplace can see it
set "OSGEO4W_ROOT=%REPO_ROOT%"

REM Ensure the log directory exists. All activity is appended into a
REM timestamped file under var\log plus a stable reinit-latest.log for
REM quick inspection.
if not exist "%REPO_ROOT%\var\log" mkdir "%REPO_ROOT%\var\log"

REM Build timestamp using PowerShell for reliable cross-locale formatting
for /f "tokens=*" %%a in ('powershell -noprofile -command "Get-Date -Format 'yyyy-MM-dd_HHmmss'"') do set "TS=%%a"
set "LOG=%REPO_ROOT%\var\log\reinit-interactive-%TS%.log"
set "LATESTLOG=%REPO_ROOT%\var\log\reinit-interactive-latest.log"

echo === QGIS portable reinitializer (INTERACTIVE) v1.0.8 ===
echo Repository root: %REPO_ROOT%
echo Log: %LOG%
echo Latest: %LATESTLOG%
echo.

echo START: %DATE% %TIME% > "%LOG%"

REM Log a little context for diagnostic purposes
call :log "Script: portable\interactive_reinit.bat v1.0.8"
call :log "Repository root: %REPO_ROOT%"
call :log ""

REM 1) Regenerate generated wrappers/templates using textreplace (if available)
REM This step will rewrite files such as bin\setup.bat from templates and is
REM the normal installer behavior that embeds correct absolute paths.
if exist "%REPO_ROOT%\bin\textreplace.exe" (
  call :log "[Step 1/4] Running textreplace to update templates..."
  call :log "  Debug: REPO_ROOT = %REPO_ROOT%"
  call :log "  Debug: OSGEO4W_ROOT = %OSGEO4W_ROOT%"
  call :log "  Debug: textreplace.exe path = %REPO_ROOT%\bin\textreplace.exe"
  call :log "  Debug: Current directory = %CD%"
  call :log "  Debug: Now running textreplace..."
  "%REPO_ROOT%\bin\textreplace.exe" -std -t bin\setup.bat >> "%LOG%" 2>&1
  if errorlevel 1 (
    call :log "ERROR: textreplace failed (exit %ERRORLEVEL%). See log for details."
    popd
    endlocal
    exit /b 1
  ) else (
    call :log "SUCCESS: textreplace completed successfully"
  )
) else (
  call :log "[Step 1/4] Note: textreplace.exe not found in bin\ - skipping template replacement."
)
call :log ""

REM 2) Run bin\setup.bat (preferred) or etc\postinstall\setup.bat as a fallback
REM The generated setup script will perform per-install actions (env files,
REM registry of resources, etc.). If it's not present we fall back to the
REM packaged postinstall script in etc\postinstall.
if exist "%REPO_ROOT%\bin\setup.bat" (
  call :log "[Step 2/4] Calling bin\setup.bat to finish setup..."
  call "%REPO_ROOT%\bin\setup.bat" >> "%LOG%" 2>&1
  if errorlevel 1 (
    call :log "Warning: bin\setup.bat exited with error %ERRORLEVEL%"
  ) else (
    call :log "SUCCESS: bin\setup.bat completed"
  )
) else if exist "%REPO_ROOT%\etc\postinstall\setup.bat" (
  call :log "[Step 2/4] bin\setup.bat not found; calling etc\postinstall\setup.bat instead..."
  call "%REPO_ROOT%\etc\postinstall\setup.bat" >> "%LOG%" 2>&1
  if errorlevel 1 (
    call :log "Warning: etc\postinstall\setup.bat exited with error %ERRORLEVEL%"
  ) else (
    call :log "SUCCESS: etc\postinstall\setup.bat completed"
  )
) else (
  call :log "ERROR: No setup script found (bin\setup.bat or etc\postinstall\setup.bat). Cannot reinitialize automatically."
  popd
  endlocal
  exit /b 2
)
call :log ""

REM 3) Run qgis postinstall actions (if any) to create env wrappers and register resources
REM Some distributions use the qgis wrapper with a --postinstall flag to
REM finalize runtime state; call it if present to ensure consistent wrappers.
if exist "%REPO_ROOT%\bin\qgis.bat" (
  call :log "[Step 3/4] Running qgis postinstall wrapper (qgis.bat --postinstall)..."
  call "%REPO_ROOT%\bin\qgis.bat" --postinstall >> "%LOG%" 2>&1
  if errorlevel 1 (
    call :log "Warning: qgis postinstall returned %ERRORLEVEL%"
  ) else (
    call :log "SUCCESS: qgis postinstall completed"
  )
) else (
  call :log "[Step 3/4] Note: qgis.bat not present in bin\ - skipping qgis postinstall step."
)
call :log ""

REM 4) Comprehensive validation checks
call :log "[Step 4/4] Validating installation integrity..."

set "VALIDATION_ERRORS=0"

REM Check 1: Core QGIS DLL
if exist "%REPO_ROOT%\apps\qgis\bin\qgis_app.dll" (
  call :log "  [OK] apps\qgis\bin\qgis_app.dll exists"
) else (
  call :log "  [ERROR] apps\qgis\bin\qgis_app.dll not found - QGIS application files may be missing"
  set /a "VALIDATION_ERRORS+=1"
)

REM Check 2: Generated environment file
if exist "%REPO_ROOT%\bin\qgis-bin.env" (
  call :log "  [OK] bin\qgis-bin.env exists"
) else (
  call :log "  [WARNING] bin\qgis-bin.env not created - you may need to rerun etc\postinstall\qgis.bat"
)

REM Check 3: Setup script was generated
if exist "%REPO_ROOT%\bin\setup.bat" (
  call :log "  [OK] bin\setup.bat exists"
) else (
  call :log "  [WARNING] bin\setup.bat not found - template generation may have failed"
)

REM Check 4: QGIS wrapper exists
if exist "%REPO_ROOT%\bin\qgis.bat" (
  call :log "  [OK] bin\qgis.bat exists"
) else (
  call :log "  [ERROR] bin\qgis.bat not found - core wrapper missing"
  set /a "VALIDATION_ERRORS+=1"
)

REM Check 5: Python runtime exists
if exist "%REPO_ROOT%\apps\Python312\python.exe" (
  call :log "  [OK] apps\Python312\python.exe exists"
) else (
  call :log "  [ERROR] apps\Python312\python.exe not found - Python runtime missing"
  set /a "VALIDATION_ERRORS+=1"
)

REM Check 6: Sample Python script with shebang
if exist "%REPO_ROOT%\apps\Python312\Scripts\gdal_calc.py" (
  call :log "  [OK] apps\Python312\Scripts\gdal_calc.py exists"
  REM Could check shebang content but would require parsing - log it for manual review
) else (
  call :log "  [WARNING] apps\Python312\Scripts\gdal_calc.py not found"
)

REM Check 7: Environment initialization directory
if exist "%REPO_ROOT%\etc\ini\gdal.bat" (
  call :log "  [OK] etc\ini\gdal.bat exists"
) else (
  call :log "  [ERROR] etc\ini\gdal.bat not found - environment init scripts missing"
  set /a "VALIDATION_ERRORS+=1"
)

REM Check 8: o4w_env.bat bootstrap script
if exist "%REPO_ROOT%\bin\o4w_env.bat" (
  call :log "  [OK] bin\o4w_env.bat exists"
) else (
  call :log "  [ERROR] bin\o4w_env.bat not found - environment bootstrap missing"
  set /a "VALIDATION_ERRORS+=1"
)

call :log ""
if %VALIDATION_ERRORS% equ 0 (
  call :log "=== Reinitialization complete - All critical checks passed ==="
) else (
  call :log "=== Reinitialization complete with %VALIDATION_ERRORS% ERRORS - Review log for details ==="
)

echo END: %DATE% %TIME% >> "%LOG%"

REM Copy timestamped log to stable latest log
copy /Y "%LOG%" "%LATESTLOG%" >nul 2>&1

echo.
echo Reinitialization complete. Check above for any errors.
echo See %LATESTLOG% for latest summary.
echo.
echo ============================================================
echo IMPORTANT: How to launch QGIS from this location
echo ============================================================
echo.
echo Always use the wrapper script (NOT qgis-bin.exe directly):
echo   %REPO_ROOT%\bin\qgis.bat
echo.
echo Example launch commands:
echo   cd /d "%REPO_ROOT%"
echo   bin\qgis.bat
echo.
echo Or from anywhere:
echo   "%REPO_ROOT%\bin\qgis.bat"
echo.
echo DO NOT run qgis-bin.exe directly - it will fail with DLL errors!
echo The wrapper sets up the environment (PATH, PYTHONHOME, QT_PLUGIN_PATH, etc.)
echo ============================================================
echo.

popd
endlocal
exit /b %VALIDATION_ERRORS%

:log
rem log helper: echo to console AND append to log file
setlocal
set "_msg=%~1"
echo %_msg%
echo %_msg% >> "%LOG%"
endlocal & goto :eof
