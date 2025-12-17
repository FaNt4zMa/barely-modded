# Update Mods Script

#requires -Version 7.0

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("client", "server")]
    [string]$PackName
)

$ErrorActionPreference = "Stop"

$packDir = "$($PackName)-pack"

Write-Host "`n=== Mod Update Script - $($PackName.ToUpper()) ===" -ForegroundColor Cyan

# Check if pack directory exists
if (-not (Test-Path $packDir)) {
    Write-Host "Error: Pack directory '$packDir' not found" -ForegroundColor Red
    exit 1
}

Push-Location $packDir

try {
    # Check if changelog-staging.md exists
    if (-not (Test-Path "changelog-staging.md")) {
        Write-Host "Error: changelog-staging.md not found in $packDir" -ForegroundColor Red
        return
    }

    Write-Host "`nRunning packwiz update in '$((Get-Location).Path)'..." -ForegroundColor Gray

    # Ensure update-logs directory exists within the pack directory
    $logsDir = "update-logs"
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir | Out-Null
    }

    # Generate timestamped log file path
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFile = Join-Path $logsDir "$($PackName)-update-$timestamp.log"
    Write-Host "Logging packwiz update output to '$logFile'" -ForegroundColor DarkGray

    # Run packwiz update and capture output
    packwiz update -a -y *> $logFile

    # Display the output
    Get-Content $logFile | ForEach-Object { Write-Host $_ }

    # Parse the log file for updated mods
    $logContent = Get-Content $logFile -Raw

    # Check if any updates were found
    if ($logContent -notmatch "Updates found:") {
        Write-Host "`n✓ No updates available" -ForegroundColor Green
        # Use return instead of exit to ensure Pop-Location runs
        return
    }

    # Extract mod names from "Updates found:" section
    $updatedMods = @()
    $lines = Get-Content $logFile

    $inUpdatesSection = $false
    foreach ($line in $lines) {
        if ($line -match "^Updates found:") {
            $inUpdatesSection = $true
            continue
        }
        
        if ($inUpdatesSection) {
            # Stop at the "Do you want to update?" prompt
            if ($line -match "Do you want to update\?") {
                break
            }
            
            # Parse lines like: "Fast Trading: fasttrading-0.2.3+1.21.6.jar -> fasttrading-0.2.3+1.21.10-rc1.jar"
            if ($line -match "^([^:]+): .* -> .*") {
                $modName = $matches[1].Trim()
                $updatedMods += $modName
            }
        }
    }

    if ($updatedMods.Count -eq 0) {
        Write-Host "`n✓ No updates were applied" -ForegroundColor Green
        return
    }

    Write-Host "`n✓ Updated $($updatedMods.Count) mod(s)" -ForegroundColor Green

    # Read current changelog-staging.md
    $stagingContent = Get-Content "changelog-staging.md" -Raw

    # Build the updated mods section
    $modsSection = "- Updated mods to their latest version`n"
    foreach ($mod in $updatedMods) {
        $modsSection += "  - $mod`n"
    }
    $modsSection += "`n"

    # Insert into the Changed section
    # Find the ### Changed section and insert after it
    if ($stagingContent -match "(?s)(### Changed\s*)") {
        # Insert the mods list after "### Changed"
        $stagingContent = $stagingContent -replace "(### Changed\s*\n)", "`$1$modsSection"
        
        Set-Content -Path "changelog-staging.md" -Value $stagingContent -NoNewline
        
        Write-Host "`n✓ Updated changelog-staging.md" -ForegroundColor Green
        Write-Host "`nAdded to changelog:" -ForegroundColor Cyan
        Write-Host $modsSection -ForegroundColor White
    } else {
        Write-Host "`nWarning: Could not find '### Changed' section in changelog-staging.md" -ForegroundColor Yellow
        Write-Host "Please manually add the following:" -ForegroundColor Yellow
        Write-Host $modsSection -ForegroundColor White
    }
} finally {
    Pop-Location
}