# Modpack Export Script

#requires -Version 7.0

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("client", "server")]
    [string]$PackName
)

$ErrorActionPreference = "Stop"

$packDir = Join-Path $PSScriptRoot "$($PackName)-pack"

# Read Minecraft and loader versions from pack-config.yml
$config = Get-Content "$PSScriptRoot\pack-config.yml" -Raw
$packNameFromFile = $config | Select-String -Pattern "(?sm)^${PackName}:.*?pack_name: `"(.*?)`"" -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
$modrinthId = $config | Select-String -Pattern "(?sm)^${PackName}:.*?modrinth_id: `"(.*?)`"" -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
$minecraftVersion = $config | Select-String -Pattern "(?sm)^${PackName}:.*?minecraft_version: `"(.*?)`"" -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
$loaderVersion = $config | Select-String -Pattern "(?sm)^${PackName}:.*?loader_version: `"(.*?)`"" -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }

if ([string]::IsNullOrWhiteSpace($packNameFromFile)) {
    Write-Host "Error: Could not find pack_name for $PackName in pack-config.yml" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($modrinthId)) {
    Write-Host "Error: Could not find modrinth_id for $PackName in pack-config.yml" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($minecraftVersion)) {
    Write-Host "Error: Could not find minecraft_version for $PackName in pack-config.yml" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($loaderVersion)) {
    Write-Host "Error: Could not find loader_version for $PackName in pack-config.yml" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Modpack Export Script - $($PackName.ToUpper()) ===" -ForegroundColor Cyan
Write-Host "Minecraft version: " -NoNewline
Write-Host $minecraftVersion -ForegroundColor Yellow
Write-Host "Loader version: " -NoNewline
Write-Host $loaderVersion -ForegroundColor Yellow

# Get version from version.txt
$versionFile = Join-Path $packDir "version.txt"
if (-not (Test-Path $versionFile)) {
    Write-Host "Error: $versionFile not found!" -ForegroundColor Red
    Write-Host "Please create version.txt with your version number (e.g., 2.4.2)" -ForegroundColor Yellow
    exit 1
}

$newVer = (Get-Content $versionFile -Raw).Trim()

if ([string]::IsNullOrWhiteSpace($newVer)) {
    Write-Host "Error: version.txt is empty" -ForegroundColor Red
    exit 1
}

Write-Host "Exporting version: " -NoNewline
Write-Host $newVer -ForegroundColor Yellow

# Files to update with version placeholder
$versionFiles = @(
    (Join-Path $packDir "pack.toml"),
    (Join-Path $packDir "config/simpleupdatechecker_modpack.json")
)

Write-Host "`nStep 1: Backing up and updating version files..." -ForegroundColor Cyan

# Update version in all tracked files
foreach ($file in $versionFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ Updating $file" -ForegroundColor Green
        Copy-Item $file "$file.bkp"
        $content = Get-Content $file -Raw
        $content = $content -replace '<PACKNAME>', $packNameFromFile
        $content = $content -replace '<MODPACKVERSION>', $newVer
        $content = $content -replace '<MINECRAFTVERSION>', $minecraftVersion
        $content = $content -replace '<FABRICVERSION>', $loaderVersion
        $content = $content -replace '<PROJECTID>', $modrinthId
        Set-Content -Path $file -Value $content -NoNewline
    } else {
        Write-Host "  ⚠ Skipping $file (not found)" -ForegroundColor Yellow
    }
}

Write-Host "`nStep 2: Processing custom datapacks..." -ForegroundColor Cyan

# Parse custom datapacks for this pack type
$datapacksPattern = "(?sm)^${PackName}:.*?custom_datapacks:(.*?)(?=^\S|\z)"
$datapacksMatch = $config | Select-String -Pattern $datapacksPattern
$zippedFiles = @()
$datapackFolders = @()
$packwizIgnorePath = Join-Path $packDir ".packwizignore"
$packwizIgnoreBackup = $null

if ($datapacksMatch) {
    $datapacksSection = $datapacksMatch.Matches.Groups[1].Value
    
    # Extract folder and version pairs
    $folderMatches = [regex]::Matches($datapacksSection, 'folder:\s*"?([^"\n]+)"?')
    $versionMatches = [regex]::Matches($datapacksSection, 'version:\s*"?([^"\n]+)"?')
    
    if ($folderMatches.Count -gt 0 -and $folderMatches.Count -eq $versionMatches.Count) {
        $datapacksDir = Join-Path $packDir "datapacks"
        
        # Backup and modify .packwizignore
        if (Test-Path $packwizIgnorePath) {
            $packwizIgnoreBackup = Get-Content $packwizIgnorePath -Raw
            Write-Host "  ✓ Backing up .packwizignore" -ForegroundColor Green
        }
        
        for ($i = 0; $i -lt $folderMatches.Count; $i++) {
            $folder = $folderMatches[$i].Groups[1].Value.Trim()
            $version = $versionMatches[$i].Groups[1].Value.Trim()
            $sourcePath = Join-Path $datapacksDir $folder
            $zipName = "$folder-v$version.zip"
            $zipPath = Join-Path $datapacksDir $zipName
            
            if (Test-Path $sourcePath) {
                Write-Host "  ✓ Zipping $folder -> $zipName" -ForegroundColor Green
                
                # Remove old zip if it exists
                if (Test-Path $zipPath) {
                    Remove-Item $zipPath -Force
                }
                
                # Zip the folder
                Compress-Archive -Path "$sourcePath\*" -DestinationPath $zipPath -Force
                $zippedFiles += $zipPath
                $datapackFolders += $folder
            } else {
                Write-Host "  ⚠ Skipping $folder (folder not found)" -ForegroundColor Yellow
            }
        }
        
        # Add folders to .packwizignore temporarily
        if ($datapackFolders.Count -gt 0) {
            $ignoreContent = if ($packwizIgnoreBackup) { $packwizIgnoreBackup } else { "" }
            if (-not $ignoreContent.EndsWith("`n") -and $ignoreContent.Length -gt 0) {
                $ignoreContent += "`n"
            }
            foreach ($folder in $datapackFolders) {
                $ignoreContent += "datapacks/$folder/`n"
            }
            Set-Content -Path $packwizIgnorePath -Value $ignoreContent -NoNewline
            Write-Host "  ✓ Temporarily added folders to .packwizignore" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  → No custom datapacks configured" -ForegroundColor Gray
}

Write-Host "`nStep 3: Exporting modpack..." -ForegroundColor Cyan

# Create version-specific export directory
$exportDir = Join-Path $packDir "export/v$newVer"
if (-not (Test-Path $exportDir)) {
    New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
}

# Get pack name from pack.toml
$packToml = Get-Content (Join-Path $packDir "pack.toml") -Raw
if ($packToml -match 'name = "([^"]+)"') {
    $packNameString = $matches[1] -replace '\s+', '-'
    $packNameString = $packNameString.ToLower()
} else {
    $packNameString = "modpack"
}

$outputFile = Join-Path $exportDir "$packNameString-$newVer.mrpack"

Push-Location $packDir
packwiz modrinth export --output $outputFile
Pop-Location

Write-Host "`nStep 4: Restoring original files..." -ForegroundColor Cyan

# Restore version files
foreach ($file in $versionFiles) {
    if (Test-Path "$file.bkp") {
        Remove-Item $file -Force
        Move-Item "$file.bkp" $file -Force
        Write-Host "  ✓ Restored $file" -ForegroundColor Green
    }
}

# Clean up zipped datapacks
if ($zippedFiles -and $zippedFiles.Count -gt 0) {
    Write-Host "  ✓ Cleaning up temporary zip files" -ForegroundColor Green
    foreach ($zipFile in $zippedFiles) {
        if (Test-Path $zipFile) {
            Remove-Item $zipFile -Force
        }
    }
}

# Restore .packwizignore
if ($null -ne $packwizIgnoreBackup) {
    Set-Content -Path $packwizIgnorePath -Value $packwizIgnoreBackup -NoNewline
    Write-Host "  ✓ Restored .packwizignore" -ForegroundColor Green
}

Push-Location $packDir
packwiz refresh
Pop-Location

Write-Host "`n✓ Export complete!" -ForegroundColor Green
Write-Host "Output: " -NoNewline
Write-Host $outputFile -ForegroundColor Cyan