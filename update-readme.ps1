# Combine README Script

#requires -Version 7.0

$ErrorActionPreference = "Stop"

Write-Host "`n=== Combining README Files ===`n" -ForegroundColor Cyan

# Define paths
$clientReadme = "./client-pack/readme.md"
$serverReadme = "./server-pack/readme.md"
$outputReadme = "./README.md"

# Check if source files exist
if (-not (Test-Path $clientReadme)) {
    Write-Host "Error: $clientReadme not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $serverReadme)) {
    Write-Host "Error: $serverReadme not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Reading client README from $clientReadme..." -ForegroundColor Green
$clientContent = (Get-Content $clientReadme -Raw).Trim()

Write-Host "Reading server README from $serverReadme..." -ForegroundColor Green
$serverContent = (Get-Content $serverReadme -Raw).Trim()

# Combine with headers
$combined = @"
# Client Pack

$clientContent

---

# Server Pack

$serverContent
"@

# Write to main README
Set-Content -Path $outputReadme -Value $combined
Write-Host "`n✓ Combined README written to $outputReadme" -ForegroundColor Green