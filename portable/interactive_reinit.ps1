# interactive_reinit.ps1 - Reinitialize this portable QGIS tree after copying to a new path
#
# Background: the OSGeo4W/QGIS portable tree writes several generated
# wrapper and environment files at install time. Those files often embed
# absolute paths. When the tree is copied to a new location the generated
# files may point to the old path and QGIS will fail to load with DLL
# loader errors (e.g. "qgis_app.dll not found"). This helper attempts to
# re-run the template patching and postinstall steps to recreate those
# generated files for the current tree location.
#
# This is the INTERACTIVE version that provides real-time console feedback.
# For automated/silent operation, use silent_reinit.ps1 instead.

$ErrorActionPreference = "Continue"
$VERSION = "1.1.2"

# Resolve repo root (script is located in portable\; parent is repo root)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO_ROOT = (Get-Item (Join-Path $ScriptDir "..")).FullName
Set-Location $REPO_ROOT

# Set OSGEO4W_ROOT for textreplace and other tools
$env:OSGEO4W_ROOT = $REPO_ROOT

# Ensure log directory exists
$LogDir = Join-Path $REPO_ROOT "var\log"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# Build timestamp
$TS = Get-Date -Format "yyyy-MM-dd_HHmmss"
$LOG = Join-Path $LogDir "reinit-interactive-${TS}.log"
$LATESTLOG = Join-Path $LogDir "reinit-interactive-latest.log"

Write-Host "=== QGIS portable reinitializer (INTERACTIVE) v$VERSION ===" -ForegroundColor Cyan
Write-Host "Repository root: $REPO_ROOT"
Write-Host "Log: $LOG"
Write-Host "Latest: $LATESTLOG"
Write-Host ""

# Initialize log file
"START: $(Get-Date)" | Out-File -FilePath $LOG -Encoding UTF8

function Write-Log {
    param([string]$Message)
    Write-Host $Message
    $Message | Out-File -FilePath $LOG -Append -Encoding UTF8
}

Write-Log "Script: portable\interactive_reinit.ps1 v$VERSION"
Write-Log "Repository root: $REPO_ROOT"
Write-Log "OSGEO4W_ROOT set to: $env:OSGEO4W_ROOT"
Write-Log ""

$VALIDATION_ERRORS = 0

# Step 1: Regenerate generated wrappers/templates using textreplace (if available)
$TextReplaceExe = Join-Path $REPO_ROOT "bin\textreplace.exe"
if (Test-Path $TextReplaceExe) {
    Write-Log "[Step 1/4] Running textreplace to update templates..."
    Write-Log "  Debug: Calling textreplace through cmd.exe to ensure environment propagates..."
    try {
        # Call through cmd.exe to ensure OSGEO4W_ROOT is visible to the executable
        $output = & cmd /c "set OSGEO4W_ROOT=$env:OSGEO4W_ROOT && `"$TextReplaceExe`" -std -t bin\setup.bat" 2>&1
        $output | Out-File -FilePath $LOG -Append -Encoding UTF8
        if ($LASTEXITCODE -ne 0) {
            Write-Log "ERROR: textreplace failed (exit $LASTEXITCODE). See log for details."
            Copy-Item $LOG $LATESTLOG -Force
            exit 1
        } else {
            Write-Log "SUCCESS: textreplace completed successfully"
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

# Step 2: Run bin\setup.bat (preferred) or etc\postinstall\setup.bat as a fallback
$SetupBat = Join-Path $REPO_ROOT "bin\setup.bat"
$FallbackSetupBat = Join-Path $REPO_ROOT "etc\postinstall\setup.bat"

if (Test-Path $SetupBat) {
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

Write-Host ""
Write-Host "Reinitialization complete. Check above for any errors."
Write-Host "See $LATESTLOG for latest summary."
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "IMPORTANT: How to launch QGIS from this location" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Always use the wrapper script (NOT qgis-bin.exe directly):"
Write-Host "  $REPO_ROOT\bin\qgis.bat" -ForegroundColor Green
Write-Host ""
Write-Host "Example launch commands:"
Write-Host "  cd /d `"$REPO_ROOT`""
Write-Host "  bin\qgis.bat"
Write-Host ""
Write-Host "Or from anywhere:"
Write-Host "  `"$REPO_ROOT\bin\qgis.bat`""
Write-Host ""
Write-Host "DO NOT run qgis-bin.exe directly - it will fail with DLL errors!" -ForegroundColor Red
Write-Host "The wrapper sets up the environment (PATH, PYTHONHOME, QT_PLUGIN_PATH, etc.)"
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

exit $VALIDATION_ERRORS
