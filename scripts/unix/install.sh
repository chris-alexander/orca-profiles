#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NO_BACKUP=false

for arg in "$@"; do
  case "$arg" in
    --no-backup) NO_BACKUP=true ;;
  esac
done

# Orca paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  ORCA_DEFAULT="$HOME/Library/Application Support/OrcaSlicer/user/default"
  ORCA_ASSETS_BED="$HOME/Library/Application Support/OrcaSlicer/assets/bed"
  ORCA_BACKUPS="$HOME/Library/Application Support/OrcaSlicer/backups"
else
  ORCA_DEFAULT="$HOME/.config/OrcaSlicer/user/default"
  ORCA_ASSETS_BED="$HOME/.config/OrcaSlicer/assets/bed"
  ORCA_BACKUPS="$HOME/.config/OrcaSlicer/backups"
fi

# Bed asset filenames tracked in repo
BED_MODEL_NAME="bed_220x220_with_tab.stl"
BED_TEXTURE_NAME="bed_220x220_grid.svg"

patch_machine_presets () {
  local machine_dir="$1"
  local assets_bed="$2"

  local model_path="$assets_bed/$BED_MODEL_NAME"
  local texture_path="$assets_bed/$BED_TEXTURE_NAME"

  [[ -d "$machine_dir" ]] || return 0

  for f in "$machine_dir"/*.json; do
    [[ -f "$f" ]] || continue

    if grep -q '"bed_custom_model"' "$f" || grep -q '"bed_custom_texture"' "$f"; then
      perl -0777 -pe \
        's/"bed_custom_model"\s*:\s*"[^"]*"/"bed_custom_model": "'"$model_path"'"/g;
         s/"bed_custom_texture"\s*:\s*"[^"]*"/"bed_custom_texture": "'"$texture_path"'"/g;' \
        -i "$f"
      echo "Patched bed asset paths in: $(basename "$f")"
    fi
  done
}

echo "Repo root: $REPO_ROOT"
echo "Orca presets: $ORCA_DEFAULT"
echo "Orca bed assets: $ORCA_ASSETS_BED"
echo "Mode: install (NO_BACKUP=$NO_BACKUP)"

if [[ "$NO_BACKUP" == false ]]; then
  TS="$(date +%F_%H%M%S)"
  BACKUP_DIR="$ORCA_BACKUPS/backup_$TS"
  mkdir -p "$BACKUP_DIR"

  echo "Backup created at: $BACKUP_DIR"

  if [[ -d "$ORCA_DEFAULT" ]]; then
    mkdir -p "$BACKUP_DIR/user/default"
    cp -a "$ORCA_DEFAULT/"* "$BACKUP_DIR/user/default/" 2>/dev/null || true
  fi

  if [[ -d "$ORCA_ASSETS_BED" ]]; then
    mkdir -p "$BACKUP_DIR/assets/bed"
    cp -a "$ORCA_ASSETS_BED/"* "$BACKUP_DIR/assets/bed/" 2>/dev/null || true
  fi
fi

mkdir -p "$ORCA_DEFAULT/filament" "$ORCA_DEFAULT/machine" "$ORCA_DEFAULT/process"
mkdir -p "$ORCA_ASSETS_BED"

cp -f "$REPO_ROOT/profiles/filament/"*.json "$ORCA_DEFAULT/filament/" 2>/dev/null || true
cp -f "$REPO_ROOT/profiles/filament/"*.info "$ORCA_DEFAULT/filament/" 2>/dev/null || true

cp -f "$REPO_ROOT/profiles/machine/"*.json "$ORCA_DEFAULT/machine/" 2>/dev/null || true
cp -f "$REPO_ROOT/profiles/machine/"*.info "$ORCA_DEFAULT/machine/" 2>/dev/null || true

cp -f "$REPO_ROOT/profiles/process/"*.json "$ORCA_DEFAULT/process/" 2>/dev/null || true
cp -f "$REPO_ROOT/profiles/process/"*.info "$ORCA_DEFAULT/process/" 2>/dev/null || true

cp -f "$REPO_ROOT/assets/bed/"*.stl "$ORCA_ASSETS_BED/" 2>/dev/null || true
cp -f "$REPO_ROOT/assets/bed/"*.svg "$ORCA_ASSETS_BED/" 2>/dev/null || true
cp -f "$REPO_ROOT/assets/bed/"*.scad "$ORCA_ASSETS_BED/" 2>/dev/null || true

echo "Patching machine preset bed asset paths..."
patch_machine_presets "$ORCA_DEFAULT/machine" "$ORCA_ASSETS_BED"

echo "Done. Restart OrcaSlicer."
