param(
  [switch]$Prune
)

# Export Orca presets -> repo (copy-based) + show diff + warn on large changes
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$orcaRoot = Join-Path $env:APPDATA "OrcaSlicer\user\default"

function Assert-Git {
  try {
    git --version | Out-Null
  } catch {
    Write-Error "git is not available in PATH. Install Git for Windows."
    exit 1
  }
}

Assert-Git

$map = @(
  @{ Name="filament"; Src=(Join-Path $orcaRoot "filament"); Dst=(Join-Path $repoRoot "profiles\filament") },
  @{ Name="machine";  Src=(Join-Path $orcaRoot "machine");  Dst=(Join-Path $repoRoot "profiles\machine")  },
  @{ Name="process";  Src=(Join-Path $orcaRoot "process");  Dst=(Join-Path $repoRoot "profiles\process")  }
)

Write-Host "Repo root: $repoRoot"
Write-Host "Orca root: $orcaRoot"

if ($Prune) {
  Write-Host "Prune mode enabled: repo profile folders will be replaced by Orca contents."
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $repoRoot "profiles\filament")
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $repoRoot "profiles\machine")
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $repoRoot "profiles\process")
}

foreach ($item in $map) {
  if (-not (Test-Path $item.Src)) {
    Write-Warning "Source folder missing: $($item.Src) (skipping $($item.Name))"
    continue
  }

  New-Item -ItemType Directory -Force -Path $item.Dst | Out-Null

  Write-Host "`nExporting $($item.Name):"
  Write-Host "  $($item.Src) -> $($item.Dst)"

  Copy-Item -Force -Path (Join-Path $item.Src "*.json") -Destination $item.Dst -ErrorAction SilentlyContinue
  Copy-Item -Force -Path (Join-Path $item.Src "*.info") -Destination $item.Dst -ErrorAction SilentlyContinue
}

# ---- Git reporting / safety ----
Write-Host "`n=== Git status (after export) ==="
$porcelain = git -C $repoRoot status --porcelain
if ($porcelain) {
  $porcelain
} else {
  Write-Host "(clean)"
}

$changedCount = 0
if ($porcelain) {
  $changedCount = ($porcelain | Measure-Object).Count
}

if ($changedCount -gt 25) {
  Write-Warning "Large change detected ($changedCount files changed). Double-check before committing."
}

Write-Host "`n=== Summary diff (names only) ==="
git -C $repoRoot diff --name-status

Write-Host "`n=== Diff (first ~200 lines) ==="
git -C $repoRoot diff | Select-Object -First 200 | ForEach-Object { $_ }

Write-Host "`nDone. Review the diff above before committing."
