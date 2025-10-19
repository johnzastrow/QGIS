<#
Validate minimal portable QGIS runtime layout (PowerShell).

Exit codes:
 - 0: all checks passed
 - 1: at least one required file/dir missing
#>

param(
    [string]$Root = $env:QGIS_ROOT
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
