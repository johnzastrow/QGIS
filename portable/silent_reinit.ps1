# silent_reinit.ps1 - Reinitialize this portable QGIS tree after copying to a new path
#
# Background: the OSGeo4W/QGIS portable tree writes several generated
# wrapper and environment files at install time. Those files often embed
# absolute paths. When the tree is copied to a new location the generated
# files may point to the old path and QGIS will fail to load with DLL
# loader errors (e.g. "qgis_app.dll not found"). This helper attempts to
# re-run the template patching and postinstall steps to recreate those
# generated files for the current tree location.
#
# This is the SILENT version that only logs to files (no console output during execution).
# For interactive operation with real-time feedback, use interactive_reinit.ps1 instead.
#
# Examples:
#   Run silently (recommended for automation):
#     powershell -ExecutionPolicy Bypass -File .\portable\silent_reinit.ps1
#
#   Enable debug logging into the silent logs (still no console spam):
#     powershell -ExecutionPolicy Bypass -File .\portable\silent_reinit.ps1 -Debug
#
# Note: these scripts avoid launching GUI installers (osgeo4w-setup.exe). If your
# tree includes a GUI installer, the scripts will skip running it and log instructions
# for non-interactive alternatives (for example, RunQGIS.bat --yes).

param(
    [switch]$Debug
)

$ErrorActionPreference = "Continue"
$VERSION = "1.1.7"

# Resolve repo root (script is located in portable\; parent is repo root)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO_ROOT = (Get-Item (Join-Path $ScriptDir "..")).FullName
Set-Location $REPO_ROOT

# Set OSGEO4W_ROOT for textreplace and other tools
$env:OSGEO4W_ROOT = $REPO_ROOT

# MSYS-style fallback variable for scripts that check it
if (-not $env:OSGEO4W_ROOT_MSYS -or $env:OSGEO4W_ROOT_MSYS -eq "") {
    $env:OSGEO4W_ROOT_MSYS = $REPO_ROOT -replace '\\', '/'
}

# Ensure log directory exists
$LogDir = Join-Path $REPO_ROOT "var\log"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# Build timestamp
$TS = Get-Date -Format "yyyy-MM-dd_HHmmss"
$LOG = Join-Path $LogDir "reinit-silent-${TS}.log"
$LATESTLOG = Join-Path $LogDir "reinit-silent-latest.log"

# Initialize log file
"START: $(Get-Date)" | Out-File -FilePath $LOG -Encoding UTF8

function Write-Log {
    param([string]$Message)
    $Message | Out-File -FilePath $LOG -Append -Encoding UTF8
}

Write-Log "Script: portable\silent_reinit.ps1 v$VERSION"
Write-Log "Repository root: $REPO_ROOT"
Write-Log "OSGEO4W_ROOT set to: $env:OSGEO4W_ROOT"
Write-Log ""

$VALIDATION_ERRORS = 0

# Step 1: Regenerate generated wrappers/templates using textreplace (if available)
$TextReplaceExe = Join-Path $REPO_ROOT "bin\textreplace.exe"
if (Test-Path $TextReplaceExe) {
    Write-Log "[Step 1/4] Running textreplace to update templates..."
    try {
        # Try direct call first (inherits PowerShell env)
        if ($Debug) { Write-Log "  Debug: calling textreplace directly: $TextReplaceExe -std -t bin\setup.bat" }
        $output = & "$TextReplaceExe" -std -t "bin\setup.bat" 2>&1
        $output | Out-File -FilePath $LOG -Append -Encoding UTF8
        $directExit = $LASTEXITCODE
        if ($directExit -eq 0 -and ($output -notmatch "Missing OSGEO4W_ROOT")) {
            Write-Log "SUCCESS: textreplace completed successfully (direct call)"
        } else {
            Write-Log "  Debug: direct call returned exit $directExit or indicated missing env; falling back to cmd.exe wrapper..."
            $cmd = 'set "OSGEO4W_ROOT=' + ($env:OSGEO4W_ROOT) + '" && '
            $cmd += 'set "OSGEO4W_ROOT_MSYS=' + ($env:OSGEO4W_ROOT_MSYS) + '" && '
            $cmd += '"' + $TextReplaceExe + '" -std -t bin\\setup.bat'
            if ($Debug) { Write-Log "  Debug: cmd fallback command: $cmd" }
            $output = & cmd /c $cmd 2>&1
            $output | Out-File -FilePath $LOG -Append -Encoding UTF8
            if ($LASTEXITCODE -ne 0) {
                Write-Log "ERROR: textreplace failed (exit $LASTEXITCODE). See log for details."
                Copy-Item $LOG $LATESTLOG -Force
                exit 1
            } else {
                Write-Log "SUCCESS: textreplace completed successfully (cmd fallback)"
            }
        }
    } catch {
        Write-Log "ERROR: textreplace exception: $_"
        Copy-Item $LOG $LATESTLOG -Force
        exit 1
    }
} else {
    Write-Log "[Step 1/4] Note: textreplace.exe not found in bin\ - skipping template replacement."
}
Write-Log ""

# Step 2.5: Update bin\qgis-bin.env (backup + patch)
Write-Log "[Step 2.5] Ensure bin\qgis-bin.env matches this tree (backup + update)..."
$EnvFile = Join-Path $REPO_ROOT "bin\qgis-bin.env"
$TmpEnv = "$EnvFile.tmp"
if (Test-Path $EnvFile) {
    try {
        $orig = Get-Content -Path $EnvFile -Raw -ErrorAction Stop
        $oldRoot = $null
        if ($orig -match "(?m)^OSGEO4W_ROOT=(.+)$") { $oldRoot = $matches[1].Trim() }
        if (-not $oldRoot) {
            if ($orig -match "(?i)([A-Za-z]:\\[^\s]+apps\\qgis)") { $oldRoot = $matches[1] }
        }
        if (-not $oldRoot) { Write-Log "  Debug: could not detect old root in qgis-bin.env; skipping automatic path patching." }

        $bak = Join-Path (Split-Path $EnvFile) ("qgis-bin.env.bak-$TS")
        Copy-Item -Path $EnvFile -Destination $bak -Force
        Write-Log "  Backed up existing qgis-bin.env to: $bak"

        if (Test-Path $TextReplaceExe) {
            Write-Log "  Debug: textreplace available, attempting to regenerate env via textreplace..."
            $trOutput = & "$TextReplaceExe" -std -t $TmpEnv 2>&1
            $trOutput | Out-File -FilePath $LOG -Append -Encoding UTF8
            if ($LASTEXITCODE -eq 0 -and (Test-Path $TmpEnv)) {
                Move-Item -Path $TmpEnv -Destination $EnvFile -Force
                Write-Log "  SUCCESS: qgis-bin.env regenerated by textreplace"
            } else {
                Write-Log "  Debug: textreplace did not produce env; falling back to safe replace"
            }
        }

        if (-not (Test-Path $EnvFile)) {
            if ($oldRoot) {
                $new = $orig -replace [regex]::Escape($oldRoot), $REPO_ROOT
                $oldRootFs = $oldRoot -replace '\\','/' 
                $new = $new -replace [regex]::Escape($oldRootFs), ($REPO_ROOT -replace '\\','/')
                $new = $new -replace "(?m)^OSGEO4W_ROOT=.*$", "OSGEO4W_ROOT=$REPO_ROOT"
                $new = $new -replace "(?m)^PYTHONHOME=.*$", "PYTHONHOME=$(Join-Path $REPO_ROOT 'apps\Python312')"
                $qgisPrefix = ($REPO_ROOT -replace '\\','/') + "/apps/qgis"
                $new = $new -replace "(?m)^QGIS_PREFIX_PATH=.*$", "QGIS_PREFIX_PATH=$qgisPrefix"

                Set-Content -Path $TmpEnv -Value $new -Encoding UTF8
                Move-Item -Path $TmpEnv -Destination $EnvFile -Force
                Write-Log "  SUCCESS: qgis-bin.env updated with new tree paths"
            } else {
                Write-Log "  WARNING: qgis-bin.env not patched because old root could not be determined"
            }
        }
    } catch {
        Write-Log "  ERROR: Failed to update qgis-bin.env: $_"
        if (Test-Path $bak) { Copy-Item -Path $bak -Destination $EnvFile -Force }
    }
} else {
    Write-Log "  Note: bin\qgis-bin.env not present, nothing to update"
}
Write-Log ""

# Step 2: Run bin\setup.bat (preferred) or etc\postinstall\setup.bat as a fallback
$SetupBat = Join-Path $REPO_ROOT "bin\setup.bat"
$FallbackSetupBat = Join-Path $REPO_ROOT "etc\postinstall\setup.bat"

# Do not run GUI installers automatically. If bin\osgeo4w-setup.exe exists, skip running setup.bat.
$GuiInstaller = Join-Path $REPO_ROOT "bin\osgeo4w-setup.exe"
# Detect if setup.bat references the GUI installer
$SetupBatContainsGui = $false
if (Test-Path $SetupBat) {
    try {
        $content = Get-Content -Path $SetupBat -ErrorAction SilentlyContinue -Raw
        if ($content -match "osgeo4w-setup.exe") { $SetupBatContainsGui = $true }
    } catch {
        # ignore
    }
}

if (Test-Path $SetupBat) {
    if ((Test-Path $GuiInstaller) -or $SetupBatContainsGui) {
        Write-Log "[Step 2/4] bin\setup.bat would launch GUI installer (osgeo4w-setup.exe) or references it; skipping automatic run."
        Write-Log "  To complete installation non-interactively, run RunQGIS.bat --yes or use the -y flag where supported."
        Write-Log "  Alternatively, run the installer interactively: $GuiInstaller"
    } else {
        Write-Log "[Step 2/4] Calling bin\setup.bat to finish setup..."
        try {
            $output = & cmd /c "`"$SetupBat`"" 2>&1
            $output | Out-File -FilePath $LOG -Append -Encoding UTF8
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Warning: bin\setup.bat exited with error $LASTEXITCODE"
            } else {
                Write-Log "SUCCESS: bin\setup.bat completed"
            }
        } catch {
            Write-Log "Warning: bin\setup.bat exception: $_"
        }
    }
} elseif (Test-Path $FallbackSetupBat) {
    Write-Log "[Step 2/4] bin\setup.bat not found; calling etc\postinstall\setup.bat instead..."
    try {
        $output = & cmd /c "`"$FallbackSetupBat`"" 2>&1
        $output | Out-File -FilePath $LOG -Append -Encoding UTF8
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Warning: etc\postinstall\setup.bat exited with error $LASTEXITCODE"
        } else {
            Write-Log "SUCCESS: etc\postinstall\setup.bat completed"
        }
    } catch {
        Write-Log "Warning: etc\postinstall\setup.bat exception: $_"
    }
} else {
    Write-Log "ERROR: No setup script found (bin\setup.bat or etc\postinstall\setup.bat). Cannot reinitialize automatically."
    Copy-Item $LOG $LATESTLOG -Force
    exit 2
}
Write-Log ""

# Step 3: Run qgis postinstall actions
$QgisBat = Join-Path $REPO_ROOT "bin\qgis.bat"
if (Test-Path $QgisBat) {
    Write-Log "[Step 3/4] Running qgis postinstall wrapper (qgis.bat --postinstall)..."
    try {
        $output = & cmd /c "`"$QgisBat`" --postinstall" 2>&1
        $output | Out-File -FilePath $LOG -Append -Encoding UTF8
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Warning: qgis postinstall returned $LASTEXITCODE"
        } else {
            Write-Log "SUCCESS: qgis postinstall completed"
        }
    } catch {
        Write-Log "Warning: qgis postinstall exception: $_"
    }
} else {
    Write-Log "[Step 3/4] Note: qgis.bat not present in bin\ - skipping qgis postinstall step."
}
Write-Log ""

# Step 4: Comprehensive validation checks
Write-Log "[Step 4/4] Validating installation integrity..."

# Check 1: Core QGIS DLL
if (Test-Path (Join-Path $REPO_ROOT "apps\qgis\bin\qgis_app.dll")) {
    Write-Log "  [OK] apps\qgis\bin\qgis_app.dll exists"
} else {
    Write-Log "  [ERROR] apps\qgis\bin\qgis_app.dll not found - QGIS application files may be missing"
    $VALIDATION_ERRORS++
}

# Check 2: Generated environment file
if (Test-Path (Join-Path $REPO_ROOT "bin\qgis-bin.env")) {
    Write-Log "  [OK] bin\qgis-bin.env exists"
} else {
    Write-Log "  [WARNING] bin\qgis-bin.env not created - you may need to rerun etc\postinstall\qgis.bat"
}

# Check 3: Setup script was generated
if (Test-Path (Join-Path $REPO_ROOT "bin\setup.bat")) {
    Write-Log "  [OK] bin\setup.bat exists"
} else {
    Write-Log "  [WARNING] bin\setup.bat not found - template generation may have failed"
}

# Check 4: QGIS wrapper exists
if (Test-Path (Join-Path $REPO_ROOT "bin\qgis.bat")) {
    Write-Log "  [OK] bin\qgis.bat exists"
} else {
    Write-Log "  [ERROR] bin\qgis.bat not found - core wrapper missing"
    $VALIDATION_ERRORS++
}

# Check 5: Python runtime exists
if (Test-Path (Join-Path $REPO_ROOT "apps\Python312\python.exe")) {
    Write-Log "  [OK] apps\Python312\python.exe exists"
} else {
    Write-Log "  [ERROR] apps\Python312\python.exe not found - Python runtime missing"
    $VALIDATION_ERRORS++
}

# Check 6: Sample Python script with shebang
if (Test-Path (Join-Path $REPO_ROOT "apps\Python312\Scripts\gdal_calc.py")) {
    Write-Log "  [OK] apps\Python312\Scripts\gdal_calc.py exists"
} else {
    Write-Log "  [WARNING] apps\Python312\Scripts\gdal_calc.py not found"
}

# Check 7: Environment initialization directory
if (Test-Path (Join-Path $REPO_ROOT "etc\ini\gdal.bat")) {
    Write-Log "  [OK] etc\ini\gdal.bat exists"
} else {
    Write-Log "  [ERROR] etc\ini\gdal.bat not found - environment init scripts missing"
    $VALIDATION_ERRORS++
}

# Check 8: o4w_env.bat bootstrap script
if (Test-Path (Join-Path $REPO_ROOT "bin\o4w_env.bat")) {
    Write-Log "  [OK] bin\o4w_env.bat exists"
} else {
    Write-Log "  [ERROR] bin\o4w_env.bat not found - environment bootstrap missing"
    $VALIDATION_ERRORS++
}

Write-Log ""
if ($VALIDATION_ERRORS -eq 0) {
    Write-Log "=== Reinitialization complete - All critical checks passed ==="
} else {
    Write-Log "=== Reinitialization complete with $VALIDATION_ERRORS ERRORS - Review log for details ==="
}

"END: $(Get-Date)" | Out-File -FilePath $LOG -Append -Encoding UTF8

# Copy timestamped log to stable latest log
Copy-Item $LOG $LATESTLOG -Force

# Only console output: final status message
if ($VALIDATION_ERRORS -eq 0) {
    Write-Host "[v$VERSION] Reinitialization complete. See $LATESTLOG for details."
} else {
    Write-Host "[v$VERSION] Reinitialization complete with $VALIDATION_ERRORS errors. See $LATESTLOG for details."
}

exit $VALIDATION_ERRORS
