param(
  [switch]$NoBackup
)

# Install repo presets/assets -> Orca (copy-based)
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$orcaDefault   = Join-Path $env:APPDATA "OrcaSlicer\user\default"
$orcaAssetsBed = Join-Path $env:APPDATA "OrcaSlicer\assets\bed"
$orcaBackups   = Join-Path $env:APPDATA "OrcaSlicer\backups"

# Bed asset filenames tracked in repo
$bedModelName   = "bed_220x220_with_tab.stl"
$bedTextureName = "bed_220x220_grid.svg"

$map = @(
  @{ Name="filament"; Src=(Join-Path $repoRoot "profiles\filament"); Dst=(Join-Path $orcaDefault "filament") },
  @{ Name="machine";  Src=(Join-Path $repoRoot "profiles\machine");  Dst=(Join-Path $orcaDefault "machine")  },
  @{ Name="process";  Src=(Join-Path $repoRoot "profiles\process");  Dst=(Join-Path $orcaDefault "process")  }
)

function Update-BedAssetPathsInMachinePresets {
  param(
    [string]$machineDir,
    [string]$orcaAssetsBed,
    [string]$bedModelName,
    [string]$bedTextureName
  )

  $modelPath = Join-Path $orcaAssetsBed $bedModelName
  $texturePath = Join-Path $orcaAssetsBed $bedTextureName

  # JSON expects backslashes escaped
  $modelJson = $modelPath.Replace("\", "\\\\")
  $textureJson = $texturePath.Replace("\", "\\\\")

  if (-not (Test-Path $machineDir)) {
    Write-Warning "Machine preset directory does not exist: $machineDir"
    return
  }

  Get-ChildItem -Path $machineDir -Filter "*.json" -File | ForEach-Object {
    $file = $_.FullName
    $text = Get-Content -Raw -Path $file

    $patched = $false

    # Patch only if keys exist (avoid touching irrelevant presets)
    if ($text -match '"bed_custom_model"\s*:') {
      $text = [regex]::Replace(
        $text,
        '"bed_custom_model"\s*:\s*"[^"]*"',
        '"bed_custom_model": "' + $modelJson + '"'
      )
      $patched = $true
    }

    if ($text -match '"bed_custom_texture"\s*:') {
      $text = [regex]::Replace(
        $text,
        '"bed_custom_texture"\s*:\s*"[^"]*"',
        '"bed_custom_texture": "' + $textureJson + '"'
      )
      $patched = $true
    }

    if ($patched) {
      Set-Content -Path $file -Value $text -Encoding utf8
      Write-Host "Patched bed asset paths in: $($_.Name)"
    }
  }
}

Write-Host "Repo root: $repoRoot"
Write-Host "Orca default presets: $orcaDefault"
Write-Host "Orca bed assets:      $orcaAssetsBed"

if (-not $NoBackup) {
  New-Item -ItemType Directory -Force -Path $orcaBackups | Out-Null

  $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
  $backupRoot = Join-Path $orcaBackups "backup_$timestamp"
  New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

  if (Test-Path $orcaDefault) {
    $dst = Join-Path $backupRoot "user\default"
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Recurse -Force -Path (Join-Path $orcaDefault "*") -Destination $dst
  }

  if (Test-Path $orcaAssetsBed) {
    $dst = Join-Path $backupRoot "assets\bed"
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Recurse -Force -Path (Join-Path $orcaAssetsBed "*") -Destination $dst
  }

  Write-Host "Backup created at: $backupRoot"
}

# Presets
foreach ($item in $map) {
  New-Item -ItemType Directory -Force -Path $item.Dst | Out-Null

  Write-Host "`nInstalling $($item.Name):"
  Write-Host "  $($item.Src) -> $($item.Dst)"

  Copy-Item -Force -Path (Join-Path $item.Src "*.json") -Destination $item.Dst -ErrorAction SilentlyContinue
  Copy-Item -Force -Path (Join-Path $item.Src "*.info") -Destination $item.Dst -ErrorAction SilentlyContinue
}

# Bed assets
New-Item -ItemType Directory -Force -Path $orcaAssetsBed | Out-Null
Write-Host "`nInstalling bed assets:"
Write-Host "  $repoRoot\assets\bed -> $orcaAssetsBed"

Copy-Item -Force -Path (Join-Path $repoRoot "assets\bed\*.stl") -Destination $orcaAssetsBed -ErrorAction SilentlyContinue
Copy-Item -Force -Path (Join-Path $repoRoot "assets\bed\*.svg") -Destination $orcaAssetsBed -ErrorAction SilentlyContinue

# optional: keep scad local too (useful for future edits)
Copy-Item -Force -Path (Join-Path $repoRoot "assets\bed\*.scad") -Destination $orcaAssetsBed -ErrorAction SilentlyContinue

# Patch machine presets (bed model/texture paths)
Write-Host "`nPatching machine presets with installed bed asset paths..."
Update-BedAssetPathsInMachinePresets `
  -machineDir (Join-Path $orcaDefault "machine") `
  -orcaAssetsBed $orcaAssetsBed `
  -bedModelName $bedModelName `
  -bedTextureName $bedTextureName

Write-Host "`nDone. Restart OrcaSlicer."
