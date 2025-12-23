# Master Release Script

#requires -Version 7.0

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Barely Modded Release Script ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made`n" -ForegroundColor Yellow
} else {
    Write-Host "This script will prepare and tag a release for GitHub Actions`n" -ForegroundColor Gray
}

# Check if packwiz is available
try {
    packwiz | Out-Null
} catch {
    Write-Host "Error: packwiz is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if git is available
try {
    git --version | Out-Null
} catch {
    Write-Host "Error: Git is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if we're in a git repo
if (-not (Test-Path ".git")) {
    Write-Host "Error: Not in a git repository" -ForegroundColor Red
    exit 1
}

# Prompt for which pack(s) to release
Write-Host "`nWhich pack do you want to release?" -ForegroundColor Cyan
Write-Host "  1. Client pack only" -ForegroundColor White
Write-Host "  2. Server pack only" -ForegroundColor White
Write-Host "  3. Both packs" -ForegroundColor White
$choice = Read-Host "`nEnter choice (1/2/3)"

$releaseClient = $false
$releaseServer = $false

switch ($choice) {
    "1" { $releaseClient = $true }
    "2" { $releaseServer = $true }
    "3" { $releaseClient = $true; $releaseServer = $true }
    default {
        Write-Host "Invalid choice. Aborted." -ForegroundColor Red
        exit 1
    }
}

# Prompt for version number
$clientVersion = $null
$serverVersion = $null
$currentVersionClient = (Get-Content "$PSScriptRoot\client-pack\version.txt" -Raw).Trim()
$currentVersionServer = (Get-Content "$PSScriptRoot\server-pack\version.txt" -Raw).Trim()

if ($releaseClient -and $releaseServer) {
    Write-Host "`nEnter CLIENT version number (current: $currentVersionClient): " -NoNewline
    $clientVersion = Read-Host

    Write-Host "Enter SERVER version number (current: $currentVersionServer): " -NoNewline
    $serverVersion = Read-Host
}
elseif ($releaseClient) {
    Write-Host "`nEnter version number (current: $currentVersionClient): " -NoNewline
    $clientVersion = Read-Host
}
elseif ($releaseServer) {
    Write-Host "`nEnter version number (current: $currentVersionServer): " -NoNewline
    $serverVersion = Read-Host
}

# Validate version format (basic semver check)
if ($clientVersion) {
    if ([string]::IsNullOrWhiteSpace($clientVersion)) {
        Write-Host "Error: Version cannot be empty" -ForegroundColor Red
        exit 1
    }

    if ($clientVersion -notmatch '^\d+\.\d+\.\d+(-[\w.]+)?$') {
        Write-Host "Warning: Version doesn't follow semver format (e.g., 2.4.3)" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -notmatch '^[Yy]$') {
            Write-Host "Aborted." -ForegroundColor Yellow
            exit 0
        }
    }
}

if ($serverVersion) {
    if ([string]::IsNullOrWhiteSpace($serverVersion)) {
        Write-Host "Error: Version cannot be empty" -ForegroundColor Red
        exit 1
    }

    if ($serverVersion -notmatch '^\d+\.\d+\.\d+(-[\w.]+)?$') {
        Write-Host "Warning: Version doesn't follow semver format (e.g., 2.4.3)" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -notmatch '^[Yy]$') {
            Write-Host "Aborted." -ForegroundColor Yellow
            exit 0
        }
    }
}

# Confirm
Write-Host "`n--- Release Summary ---" -ForegroundColor Cyan
Write-Host ""
if ($releaseClient) { Write-Host "  • Client pack v$clientVersion" -ForegroundColor Green }
if ($releaseServer) { Write-Host "  • Server pack v$serverVersion" -ForegroundColor Green }
Write-Host ""
$confirm = Read-Host "Continue? (y/n)"

if ($confirm -notmatch '^[Yy]$') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

# Function to process a pack
function Update-Pack {
    param($packName, $packDir, $packVersion)

    Write-Host "`n=== Processing $packName ===" -ForegroundColor Cyan

    # Check if directory exists
    if (-not (Test-Path $packDir)) {
        Write-Host "Error: $packDir not found!" -ForegroundColor Red
        return @{ Success = $false }
    }

    $packNameShort = $packName.Split(' ')[0].ToLower()

    # Retain Push-Location for 'packwiz refresh' and execution context.
    Push-Location $packDir

    try {
        # Refresh packwiz index
        if (-not $DryRun) {
            Write-Host "`nRefreshing packwiz index..." -ForegroundColor Gray
            packwiz refresh
            Write-Host "✓ Done!" -ForegroundColor Green
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Error: packwiz refresh failed" -ForegroundColor Red
                return @{ Success = $false; Changelog = "" }
            }
        } else {
            Write-Host "`n[DRY RUN] Refreshing packwiz index..." -ForegroundColor Gray
            Write-Host "  [DRY RUN] packwiz refresh" -ForegroundColor DarkGray
            Write-Host "[DRY RUN] ✓ Done!" -ForegroundColor Gray
        }

        # Update version.txt
        if (-not $DryRun) {
            Write-Host "`nUpdating version.txt..." -ForegroundColor Gray
            Set-Content -Path "version.txt" -Value $packVersion
            Write-Host "✓ Done!" -ForegroundColor Green
        } else {
            Write-Host "`n[DRY RUN] Updating version.txt..." -ForegroundColor Gray
            Write-Host "  [DRY RUN] Set-Content -Path `"version.txt`" -Value $packVersion" -ForegroundColor DarkGray
            Write-Host "[DRY RUN] ✓ Done!" -ForegroundColor Gray
        }

        # Export MRPack
        if (-not (Test-Path "..\mrpack-export.ps1")) {
            Write-Host "Warning: mrpack-export.ps1 not found, skipping export" -ForegroundColor Yellow
            return @{ Success = $true; Changelog = "" }
        }

        $exportDir = "export/v$packVersion"
        if (-not $DryRun) {
            if (-not (Test-Path $exportDir)) {
                New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
            }
        }

        $exportLog = "$exportDir/export.log"
        if (-not $DryRun) {
            Write-Host "`nExporting mrpack..." -ForegroundColor Gray
            ..\mrpack-export.ps1 -PackName $packNameShort *> $exportLog
            Write-Host "✓ Done!" -ForegroundColor Green
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: MRPack export failed" -ForegroundColor Yellow
                return @{ Success = $true; Changelog = "" }
            }
        } else {
            Write-Host "`n[DRY RUN] Exporting mrpack..." -ForegroundColor Gray
            Write-Host "  [DRY RUN] ..\mrpack-export.ps1 -PackName $packNameShort" -ForegroundColor DarkGray
            Write-Host "[DRY RUN] ✓ Done!" -ForegroundColor Gray
        }

        # Generate changelog
        $changelog = ""
        if (-not (Test-Path "..\changelog-generator.ps1")) {
            Write-Host "Warning: changelog-generator.ps1 not found, skipping changelog generation" -ForegroundColor Yellow
            return @{ Success = $true; Changelog = "" }
        }

        if (-not $DryRun) {
            Write-Host "`nGenerating changelog..." -ForegroundColor Gray
            ..\changelog-generator.ps1 -PackName $packNameShort -Version $packVersion
            Write-Host "`n✓ Done!" -ForegroundColor Green
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Error: Changelog generation failed" -ForegroundColor Red
                return @{ Success = $false; Changelog = "" }
            }
        } else {
            Write-Host "`n[DRY RUN] Generating changelog..." -ForegroundColor Gray
            Write-Host "  [DRY RUN] ..\changelog-generator.ps1 -PackName $packNameShort -Version $packVersion" -ForegroundColor DarkGray
            Write-Host "[DRY RUN] ✓ Done!" -ForegroundColor Gray
        }
        
        # Read the generated changelog for preview
        if (Test-Path "changelog.md") {
            $changelogContent = Get-Content "changelog.md" -Raw
            # Extract just the latest entry (up to the next ## heading)
            if ($changelogContent -match "(?s)^(## \[$packVersion\].*?)(?=\n## \[|\z)") {
                $changelog = $matches[1].Trim()
            }
        }

        if (-not $DryRun) {
            Write-Host "`n✓ $packName prepared successfully" -ForegroundColor Green
        } else {
            Write-Host "`n[DRY RUN] ✓ $packName prepared successfully" -ForegroundColor Gray
        }

        return @{ Success = $true; Changelog = $changelog }

    } finally {
        Pop-Location
    }
}

# Process selected pack(s)
$success = $true
$clientChangelog = ""
$serverChangelog = ""

if ($releaseClient) {
    $result = Update-Pack "Client Pack" "client-pack" $clientVersion
    if (-not $result.Success) {
        $success = $false
    } else {
        $clientChangelog = $result.Changelog
    }
}

if ($releaseServer) {
    $result = Update-Pack "Server Pack" "server-pack" $serverVersion
    if (-not $result.Success) {
        $success = $false
    } else {
        $serverChangelog = $result.Changelog
    }
}

if (-not $success) {
    Write-Host "`nRelease preparation failed. Please fix errors and try again." -ForegroundColor Red
    exit 1
}

# Show changelog preview
if ($clientChangelog -or $serverChangelog) {
    Write-Host "`n=== Changelog Preview ===" -ForegroundColor Cyan
    
    if ($clientChangelog) {
        Write-Host "`nClient Pack:" -ForegroundColor Green
        Write-Host $clientChangelog -ForegroundColor White
    }
    
    if ($serverChangelog) {
        Write-Host "`nServer Pack:" -ForegroundColor Green
        Write-Host $serverChangelog -ForegroundColor White
    }
}

# Final confirmation (skip prompt in dry run)
Write-Host ""
if (-not $DryRun) {
    $proceed = Read-Host "Proceed with release? (y/n)"
    if ($proceed -notmatch '^[Yy]$') {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "[DRY RUN] Skipping final confirmation prompt" -ForegroundColor Gray
}

# Git operations
Write-Host "`n=== Git Operations ===" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "`n[DRY RUN] Would perform the following git operations:" -ForegroundColor Yellow
}

# Update combined README
if (Test-Path "update-readme.ps1") {
    if (-not $DryRun) {
        Write-Host "`nUpdating combined README..." -ForegroundColor Gray
        .\update-readme.ps1
        Write-Host "`n✓ Done!" -ForegroundColor Green
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: README update failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n[DRY RUN] Updating combined README..." -ForegroundColor Gray
        Write-Host "  [DRY RUN] .\update-readme.ps1" -ForegroundColor DarkGray
        Write-Host "[DRY RUN] ✓ Done!" -ForegroundColor Gray
    }
} else {
    Write-Host "`nWarning: update-readme.ps1 not found, skipping README update" -ForegroundColor Yellow
}

# Stage changes
if (-not $DryRun) {
    Write-Host "`nStaging changes..." -ForegroundColor Gray
    if ($releaseClient) {
        git add "client-pack"
    }
    if ($releaseServer) {
        git add "server-pack"
    }
    git add "pack-config.yml"
    git add "README.md"
} else {
    Write-Host "`n[DRY RUN] Staging changes..." -ForegroundColor Gray
    if ($releaseClient) {
        Write-Host "  [DRY RUN] git add `"client-pack`"" -ForegroundColor DarkGray
    }
    if ($releaseServer) {
        Write-Host "  [DRY RUN] git add `"server-pack`"" -ForegroundColor DarkGray
    }
    Write-Host "  [DRY RUN] git add `"pack-config.yml`"" -ForegroundColor DarkGray
    Write-Host "  [DRY RUN] git add `"README.md`"" -ForegroundColor DarkGray
}

# Detect staged changes
git diff --cached --quiet
$hasChanges = ($LASTEXITCODE -ne 0)

if (-not $hasChanges -and -not $DryRun) {
    Write-Host "No changes to commit" -ForegroundColor Gray
    exit 0
}

if (-not $hasChanges -and $DryRun) {
    Write-Host "  [DRY RUN] No staged changes detected — showing preview anyway" -ForegroundColor DarkGray
}

# Build commit message
if ($releaseClient -and $releaseServer) {
    $commitMessage = "Release client v$clientVersion and server v$serverVersion"
} elseif ($releaseClient) {
    $commitMessage = "Release client v$clientVersion"
} elseif ($releaseServer) {
    $commitMessage = "Release server v$serverVersion"
}

if ($DryRun) {
    Write-Host "  [DRY RUN] git commit -m `"$commitMessage`"" -ForegroundColor DarkGray
} else {
    Write-Host "`nCommitting changes: $commitMessage" -ForegroundColor Gray
    git commit -m $commitMessage
}

# Create tags
if ($releaseClient) {
    $clientTag = "client/v$clientVersion"
    if ($DryRun) {
        Write-Host "  [DRY RUN] git tag -a $clientTag" -ForegroundColor DarkGray
    } else {
        Write-Host "`nCreating tag: $clientTag" -ForegroundColor Gray
        git tag -a $clientTag -m "Client pack release v$clientVersion"
    }
}

if ($releaseServer) {
    $serverTag = "server/v$serverVersion"
    if ($DryRun) {
        Write-Host "  [DRY RUN] git tag -a $serverTag" -ForegroundColor DarkGray
    } else {
        Write-Host "Creating tag: $serverTag" -ForegroundColor Gray
        git tag -a $serverTag -m "Server pack release v$serverVersion"
    }
}

# Push
if (-not $DryRun) {
    Write-Host "`nPushing to remote..." -ForegroundColor Gray
    git push
    git push --tags
} else {
    Write-Host "`n[DRY RUN] Pushing to remote..." -ForegroundColor Gray
    Write-Host "  [DRY RUN] git push" -ForegroundColor DarkGray
    Write-Host "  [DRY RUN] git push --tags" -ForegroundColor DarkGray
}

if ($DryRun) {
    Write-Host "`n✓ Dry run complete! No changes were made." -ForegroundColor Green
    Write-Host "Run without -DryRun flag to perform the actual release." -ForegroundColor Gray
} else {
    Write-Host "`n✓ Release complete!" -ForegroundColor Green
    Write-Host "`nGitHub Actions will now:" -ForegroundColor Cyan
    if ($releaseClient) {
       Write-Host "  • Build and upload client pack v$clientVersion to Modrinth" -ForegroundColor Gray
    }
    if ($releaseServer) {
        Write-Host "  • Build and upload server pack v$serverVersion to Modrinth" -ForegroundColor Gray
    }
    
    Write-Host "`nMonitor progress at: https://github.com/FaNt4zMa/barely-modded/actions" -ForegroundColor Yellow
}