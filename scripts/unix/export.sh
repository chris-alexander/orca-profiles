#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PRUNE=false

for arg in "$@"; do
  case "$arg" in
    --prune) PRUNE=true ;;
  esac
done

require_git () {
  if ! command -v git >/dev/null 2>&1; then
    echo "WARNING: git not found; skipping diff/status output"
    return 1
  fi
  if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "WARNING: git repo not found; skipping diff/status output"
    return 1
  fi
  return 0
}

# Orca preset paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  ORCA_DEFAULT="$HOME/Library/Application Support/OrcaSlicer/user/default"
else
  ORCA_DEFAULT="$HOME/.config/OrcaSlicer/user/default"
fi

echo "Repo root: $REPO_ROOT"
echo "Orca root: $ORCA_DEFAULT"

mkdir -p \
  "$REPO_ROOT/profiles/filament" \
  "$REPO_ROOT/profiles/machine" \
  "$REPO_ROOT/profiles/process"

copy_dir () {
  local src="$1"
  local dst="$2"
  if [[ ! -d "$src" ]]; then
    echo "WARNING: missing source folder: $src (skipping)"
    return 0
  fi
  cp -f "$src/"*.json "$dst/" 2>/dev/null || true
  cp -f "$src/"*.info "$dst/" 2>/dev/null || true
}

if [[ "$PRUNE" == true ]]; then
  rm -rf \
    "$REPO_ROOT/profiles/filament" \
    "$REPO_ROOT/profiles/machine" \
    "$REPO_ROOT/profiles/process"
  mkdir -p \
    "$REPO_ROOT/profiles/filament" \
    "$REPO_ROOT/profiles/machine" \
    "$REPO_ROOT/profiles/process"
fi

copy_dir "$ORCA_DEFAULT/filament" "$REPO_ROOT/profiles/filament"
copy_dir "$ORCA_DEFAULT/machine"  "$REPO_ROOT/profiles/machine"
copy_dir "$ORCA_DEFAULT/process"  "$REPO_ROOT/profiles/process"

if ! require_git; then
  exit 0
fi

echo
echo "=== Git status (after export) ==="
porcelain="$(git -C "$REPO_ROOT" status --porcelain)"
if [[ -n "$porcelain" ]]; then
  echo "$porcelain"
else
  echo "(clean)"
fi

changedCount="$(echo "$porcelain" | grep -c '^[ MADRCU?!]' || true)"
if [[ "$changedCount" -gt 25 ]]; then
  echo "WARNING: Large change detected ($changedCount files changed). Double-check before committing."
fi

echo
echo "=== Summary diff (names only) ==="
git -C "$REPO_ROOT" diff --name-status || true

echo
echo "=== Diff (first ~200 lines) ==="
git -C "$REPO_ROOT" diff | sed -n '1,200p' || true

echo
echo "Done. Review the diff above before committing."
