param(
  [switch]$NoBackup
)

# Install repo presets/assets -> Orca (copy-based)
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$orcaDefault = Join-Path $env:APPDATA "OrcaSlicer\user\default"
$orcaAssetsBed = Join-Path $env:APPDATA "OrcaSlicer\assets\bed"
$orcaBackups = Join-Path $env:APPDATA "OrcaSlicer\backups"

$map = @(
  @{ Name="filament"; Src=(Join-Path $repoRoot "profiles\filament"); Dst=(Join-Path $orcaDefault "filament") },
  @{ Name="machine";  Src=(Join-Path $repoRoot "profiles\machine");  Dst=(Join-Path $orcaDefault "machine")  },
  @{ Name="process";  Src=(Join-Path $repoRoot "profiles\process");  Dst=(Join-Path $orcaDefault "process")  }
)

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

Write-Host "`nDone. Restart OrcaSlicer."
