<#
Portable environment check helper

This script invokes `bin\o4w_env.bat` inside a cmd subshell, captures
selected environment variables, and prints a human-friendly report with
recommended fix commands when variables are missing or empty.

Usage:
  powershell -ExecutionPolicy Bypass -File portable\check_env.ps1
#>

param(
    [string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path -Resolve),
    [switch]$VerboseOutput
)

$o4w = Join-Path $Root '..\bin\o4w_env.bat'
if (-not (Test-Path $o4w)) {
    Write-Host "ERROR: $o4w not found" -ForegroundColor Red
    exit 2
}

$vars = @('GDAL_DATA','GDAL_DRIVER_PATH','PROJ_DATA','PYTHONHOME','QT_PLUGIN_PATH')

# Build a cmd line that calls the bootstrap and prints the variables
$cmdArgs = ' /c call "' + $o4w + '" && ' + ($vars | ForEach-Object { "set $_" }) -join ' && '

$proc = Start-Process -FilePath cmd.exe -ArgumentList $cmdArgs -NoNewWindow -RedirectStandardOutput -PassThru
$out = $proc.StandardOutput.ReadToEnd()
$proc.WaitForExit()

if ($out.Trim().Length -eq 0) {
    Write-Host "Bootstrap did not produce any environment output. Check $o4w for errors." -ForegroundColor Red
    exit 3
}

$map = @{}
foreach ($line in $out -split "\r?\n") {
    if ($line -match '^(\w+)=(.*)$') {
        $map[$matches[1]] = $matches[2]
    }
}

Write-Host "Environment check result:" -ForegroundColor Cyan
foreach ($v in $vars) {
    if ($map.ContainsKey($v)) {
        $val = $map[$v]
        if ([string]::IsNullOrWhiteSpace($val)) {
            Write-Host "- ${v}: <empty>" -ForegroundColor Yellow
            Write-Host "    Recommended: run 'bin\\textreplace.exe -std -t bin\\setup.bat' and then 'call bin\\setup.bat' or run 'bin\\reinit.bat'" -ForegroundColor DarkYellow
        } else {
            Write-Host "- ${v}: ${val}" -ForegroundColor Green
        }
    } else {
        Write-Host "- ${v}: NOT SET" -ForegroundColor Red
        Write-Host "    Recommended: ensure etc\\ini\\<package>.bat sets ${v} or add it to etc\\ini and re-run reinit" -ForegroundColor DarkYellow
    }
}

if ($VerboseOutput) { Write-Host "\nRaw output:\n$out" }

exit 0
