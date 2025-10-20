@echo off
rem reinit_portable.bat
rem Self-contained helper to reinitialize a portable QGIS tree after copying.

setlocal enabledelayedexpansion

REM Determine repo root (script is in portable\)
for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
pushd "%REPO_ROOT%"

REM Ensure log dir
if not exist "var\log" mkdir "var\log"

REM Timestamp
for /f "tokens=1-4 delims=/ .: " %%a in ("%date% %time%") do (
    set "Y=%%d"
    set "M=00%%b"
    set "D=00%%c"
    set "T=%%e"
)
set "M=%M:~-2%"
set "D=%D:~-2%"
set "T=%T: =0%"
set "TS=%Y%-%M%-%D%_%T%"
set "LOG=var\log\reinit-%TS%.log"
set "LATESTLOG=var\log\reinit-latest.log"

echo Reinitializing portable QGIS tree at %REPO_ROOT% > "%LOG%"
echo START: %DATE% %TIME% >> "%LOG%"
echo START: %DATE% %TIME% > "%LATESTLOG%"

REM 1) Generate bin\setup.bat from templates if textreplace exists
if exist "bin\textreplace.exe" (
    echo Running textreplace... >> "%LOG%" 2>&1
    bin\textreplace.exe -std -t bin\setup.bat >> "%LOG%" 2>&1
    if errorlevel 1 (
        echo textreplace failed >> "%LOG%"
        popd
        endlocal
        exit /b 1
    )
) else (
    echo textreplace not found; skipping template generation >> "%LOG%"
)

REM 2) Call generated setup or fallback to etc\postinstall\setup.bat
if exist "bin\setup.bat" (
    echo Calling bin\setup.bat >> "%LOG%" 2>&1
    call "bin\setup.bat" >> "%LOG%" 2>&1
    if errorlevel 1 echo bin\setup.bat returned error %ERRORLEVEL% >> "%LOG%"
) else if exist "etc\postinstall\setup.bat" (
    echo Calling etc\postinstall\setup.bat >> "%LOG%" 2>&1
    call "etc\postinstall\setup.bat" >> "%LOG%" 2>&1
    if errorlevel 1 echo etc\postinstall\setup.bat returned error %ERRORLEVEL% >> "%LOG%"
) else (
    echo No setup script found; aborting >> "%LOG%"
    popd
    endlocal
    exit /b 2
)

REM 3) Optionally run qgis postinstall wrapper
if exist "bin\qgis.bat" (
    echo Running bin\qgis.bat --postinstall >> "%LOG%" 2>&1
    call "bin\qgis.bat" --postinstall >> "%LOG%" 2>&1
)

REM Final checks
if exist "apps\qgis\bin\qgis_app.dll" (
    echo OK: qgis_app.dll present >> "%LOG%"
) else (
    echo WARNING: qgis_app.dll missing >> "%LOG%"
)

copy /Y "%LOG%" "%LATESTLOG%" >nul 2>&1
echo Reinit finished. See %LATESTLOG% for summary and %LOG% for details.
popd
endlocal
exit /b 0
