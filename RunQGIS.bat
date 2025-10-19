REM RunQGIS.bat
@echo off
REM Clean up any existing setup files
DEL "%~dp0\bin\setup.bat"
if exist "%~dp0\bin\setup.bat" (
    echo Failed to delete existing setup.bat
    exit /b 1
) else (
    echo Existing setup.bat deleted successfully.
)

REM Clean up any existing environment files
DEL "%~dp0\bin\qgis-bin.env"
if exist "%~dp0\bin\qgis-bin.env" (
    echo Failed to delete existing qgis-bin.env
    exit /b 1
) else (
    echo Existing qgis-bin.env deleted successfully.
)
REM Call OSGeo4W.bat to set up the environment
call "%~dp0\OSGeo4W.bat"
if %ERRORLEVEL% neq 0 (
    echo Failed to set up OSGeo4W environment.
    exit /b %ERRORLEVEL%
) else (
    echo OSGeo4W environment set up successfully.
)

rem Launch QGIS with specific profile and project
rem @echo off
call "%~dp0\bin\qgis-bin.exe" --profiles-path "%~dp0\Profiles"  --profile "Viewer2" --project "geopackage:%~dp0\data.gpkg?projectName=main_project"

if %ERRORLEVEL% neq 0 (
    echo Failed to launch QGIS.
    exit /b %ERRORLEVEL%
)   else echo QGIS launched with custom profile and project.
