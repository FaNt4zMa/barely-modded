# Simple Changelog Generator

#requires -Version 7.0

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("client", "server")]
    [string]$PackName,

    [string]$Version
)

$ErrorActionPreference = "Stop"

$packDir = Join-Path $PSScriptRoot "$($PackName)-pack"

Write-Host "`n=== Changelog Generator - $($PackName.ToUpper()) ===" -ForegroundColor Cyan

# Get current version
$versionFile = Join-Path $packDir "version.txt"
if ($Version) {
    $currentVer = $Version
} elseif (Test-Path $versionFile) {
    $currentVer = (Get-Content $versionFile -Raw).Trim()
} else {
    Write-Host "Error: $versionFile not found and no version parameter provided!" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($currentVer)) {
    Write-Host "Error: version is empty!" -ForegroundColor Red
    exit 1
}

Write-Host "Generating changelog for $($PackName) version: " -NoNewline
Write-Host $currentVer -ForegroundColor Yellow

# Check for staging file
$stagingFile = Join-Path $packDir "changelog-staging.md"

if (-not (Test-Path $stagingFile)) {
    Write-Host "`nError: $stagingFile not found!" -ForegroundColor Red
    Write-Host "Please create $stagingFile with your changes before running this script." -ForegroundColor Yellow
    exit 1
}

# Read staging content
$stagingContent = (Get-Content $stagingFile -Raw).Trim()

if ([string]::IsNullOrWhiteSpace($stagingContent)) {
    Write-Host "`nError: $stagingFile is empty!" -ForegroundColor Red
    exit 1
}

# Generate changelog entry with date and version
$date = Get-Date -Format "yyyy-MM-dd"
$changelogEntry = @"
## [$currentVer] - $date

$stagingContent
"@

# Prepend to changelog.md
$changelogFile = Join-Path $packDir "changelog.md"
$existingChangelog = ""
if (Test-Path $changelogFile) {
    $existingChangelog = Get-Content $changelogFile -Raw
}

$newChangelog = $changelogEntry + "`n`n`n`n" + $existingChangelog
Set-Content -Path $changelogFile -Value $newChangelog -NoNewline

Write-Host "`n✓ Changelog saved to $changelogFile" -ForegroundColor Green

# Create blank staging file for next version
$stagingTemplate = @"
### Added

### Changed

### Removed

### Fixed

"@

Set-Content -Path $stagingFile -Value $stagingTemplate -NoNewline
Write-Host "`n✓ Reset $stagingFile for next version" -ForegroundColor Green