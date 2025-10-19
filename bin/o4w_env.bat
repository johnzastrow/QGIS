REM Make parent of this script location our current directory,
REM converting UNC path to drive letter if needed
pushd %~dp0
echo Current directory is %~dp0
cd ..

REM set OSGEO4W_ROOT to short path version
for %%i in ("%CD%") do set OSGEO4W_ROOT=%%~fsi echo OSGEO4W_ROOT is %OSGEO4W_ROOT%
echo OSGEO4W_ROOT is %OSGEO4W_ROOT%


REM start with clean path
set path=%OSGEO4W_ROOT%\bin;%WINDIR%\system32;%WINDIR%;%WINDIR%\system32\WBem
echo OSGEO4W_ROOT is %OSGEO4W_ROOT%

REM call all .bat files in etc\ini to set environment variables
for %%f in ("%OSGEO4W_ROOT%\etc\ini\*.bat") do call "%%f" echo Called %%f


popd
