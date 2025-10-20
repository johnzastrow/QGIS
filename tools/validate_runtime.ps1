<#
Validate minimal portable QGIS runtime layout (PowerShell).

Exit codes:
 - 0: all checks passed
 - 1: at least one required file/dir missing
#>

param(
    [string]$Root = $env:QGIS_ROOT
    [switch]$CheckEnv
)

if (-not $Root) {
    # script is located in tools\; default to parent directory of the script
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    # Use fullpath combine/getfullpath to avoid Resolve-Path returning arrays
    $Root = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir '..'))
}

Write-Host "Validating minimal QGIS runtime under: $Root"
$Required = @(
    [System.IO.Path]::Combine($Root,'bin','qgis.bat'),
    [System.IO.Path]::Combine($Root,'bin','qgis-bin.exe'),
    [System.IO.Path]::Combine($Root,'apps','qgis','bin','qgis_app.dll'),
    [System.IO.Path]::Combine($Root,'etc','ini'),
    [System.IO.Path]::Combine($Root,'Profiles')
)

$Optional = @(
    [System.IO.Path]::Combine($Root,'bin','textreplace.exe'),
    [System.IO.Path]::Combine($Root,'bin','setup.bat'),
    [System.IO.Path]::Combine($Root,'etc','postinstall','setup.bat')
)

$missing = @()
foreach ($p in $Required) {
    if (Test-Path $p) {
        Write-Host "OK:      $p"
    } else {
        Write-Host "MISSING: $p"
        $missing += $p
    }
}

Write-Host "`nOptional files (helpful but not required):"
foreach ($p in $Optional) {
    if (Test-Path $p) { Write-Host "OK:      $p" } else { Write-Host " - :    $p" }
}

if ($missing.Count -gt 0) {
    Write-Host "`nRESULT: MISSING required files/dirs. See list above."
    exit 1
} else {
    Write-Host "`nRESULT: All required files present."
    exit 0
}
if ($CheckEnv) {
    Write-Host "\nChecking computed environment variables by sourcing bin\o4w_env.bat..." -ForegroundColor Cyan
    $o4w = Join-Path $PSScriptRoot '..\bin\o4w_env.bat'
    if (-not (Test-Path $o4w)) {
        Write-Host "o4w_env.bat not found at $o4w" -ForegroundColor Yellow
        exit 2
    }

    # Run cmd.exe to call the bootstrap and echo selected variables
    $varsToCheck = @('GDAL_DATA','GDAL_DRIVER_PATH','PROJ_DATA','PYTHONHOME','QT_PLUGIN_PATH')
    $cmd = "cmd /c \"call \"$o4w\" && set " + ($varsToCheck -join ' && set ') + "\""
    $proc = Start-Process -FilePath cmd.exe -ArgumentList "/c", "call `"$o4w`" && set GDAL_DATA && set GDAL_DRIVER_PATH && set PROJ_DATA && set PYTHONHOME && set QT_PLUGIN_PATH" -NoNewWindow -RedirectStandardOutput -PassThru
    $out = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()

    if ($out.Trim().Length -eq 0) {
        Write-Host "No environment variables were printed. The bootstrap may have failed." -ForegroundColor Red
        exit 3
    }

    # Parse output lines like VAR=value
    $map = @{}
    foreach ($line in $out -split "\r?\n") {
        <#
        Validate minimal portable QGIS runtime layout (PowerShell).

        Exit codes:
         - 0: all checks passed
         - 1: at least one required file/dir missing
         - 2: o4w_env.bat missing when -CheckEnv requested
        <#
        Validate minimal portable QGIS runtime layout (PowerShell).

        Exit codes:
         - 0: all checks passed
         - 1: at least one required file/dir missing
         - 2: o4w_env.bat missing when -CheckEnv requested
        <#
        Validate minimal portable QGIS runtime layout (PowerShell).

        Exit codes:
         - 0: all checks passed
         - 1: at least one required file/dir missing
         - 2: o4w_env.bat missing when -CheckEnv requested
         - 3: check-env failed to produce output
        #>

        param(
            [string]$Root = $env:QGIS_ROOT,
            [switch]$CheckEnv
        )

        if (-not $Root) {
            # script is located in tools\; default to parent directory of the script
            $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
            # Use fullpath combine/getfullpath to avoid Resolve-Path returning arrays
            $Root = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir '..'))
        }

        Write-Host "Validating minimal QGIS runtime under: $Root"
        $Required = @(
            [System.IO.Path]::Combine($Root,'bin','qgis.bat'),
            [System.IO.Path]::Combine($Root,'bin','qgis-bin.exe'),
            [System.IO.Path]::Combine($Root,'apps','qgis','bin','qgis_app.dll'),
            [System.IO.Path]::Combine($Root,'etc','ini'),
            [System.IO.Path]::Combine($Root,'Profiles')
        )

        $Optional = @(
            [System.IO.Path]::Combine($Root,'bin','textreplace.exe'),
            [System.IO.Path]::Combine($Root,'bin','setup.bat'),
            [System.IO.Path]::Combine($Root,'etc','postinstall','setup.bat')
        )

        $missing = @()
        foreach ($p in $Required) {
            if (Test-Path $p) {
                Write-Host "OK:      $p"
            } else {
                Write-Host "MISSING: $p"
                $missing += $p
            }
        }

        Write-Host "`nOptional files (helpful but not required):"
        foreach ($p in $Optional) {
            if (Test-Path $p) { Write-Host "OK:      $p" } else { Write-Host " - :    $p" }
        }

        if ($missing.Count -gt 0) {
            Write-Host "`nRESULT: MISSING required files/dirs. See list above." -ForegroundColor Red
            exit 1
        } else {
            Write-Host "`nRESULT: All required files present." -ForegroundColor Green
        }

        if ($CheckEnv) {
            Write-Host "`nChecking computed environment variables by sourcing bin\o4w_env.bat..." -ForegroundColor Cyan
            $o4w = Join-Path $Root 'bin\o4w_env.bat'
            if (-not (Test-Path $o4w)) {
                Write-Host "o4w_env.bat not found at $o4w" -ForegroundColor Yellow
                exit 2
            }

            $varsToCheck = @('GDAL_DATA','GDAL_DRIVER_PATH','PROJ_DATA','PYTHONHOME','QT_PLUGIN_PATH')

            # Build a single command string for cmd.exe. Keep quoting simple and let Start-Process pass it as a single argument.
            $setCmds = $varsToCheck | ForEach-Object { 'set ' + $_ }
            $cmdStr = 'call "' + $o4w + '" && ' + ($setCmds -join ' && ')

            $proc = Start-Process -FilePath cmd.exe -ArgumentList '/c', $cmdStr -NoNewWindow -RedirectStandardOutput -PassThru
            $out = $proc.StandardOutput.ReadToEnd()
            $proc.WaitForExit()

            if ([string]::IsNullOrWhiteSpace($out)) {
                Write-Host "No environment variables were printed. The bootstrap may have failed." -ForegroundColor Red
                exit 3
            }

            # Parse output lines like VAR=value
            $map = @{}
            foreach ($line in $out -split "`n") {
                if ($line -match '^(\w+)=(.*)$') {
                    $map[$matches[1]] = $matches[2]
                }
            }

            foreach ($v in $varsToCheck) {
                if ($map.ContainsKey($v)) {
                    $val = $map[$v]
                    if ([string]::IsNullOrWhiteSpace($val)) {
                        Write-Host "${v} = <empty>" -ForegroundColor Yellow
                        Write-Host "  Recommended: run bin\textreplace.exe -std -t bin\setup.bat and then call bin\setup.bat (or run bin\reinit.bat)" -ForegroundColor DarkYellow
                    } else {
                        Write-Host "${v} = ${val}" -ForegroundColor Green
                    }
                } else {
                    Write-Host "${v} not set" -ForegroundColor Red
                    Write-Host "  Recommended: ensure bin\o4w_env.bat sources etc\ini\*.bat and that etc\ini contains ${v} assignment." -ForegroundColor DarkYellow
                }
            }

            exit 0
        }
