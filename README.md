# orca-profiles

Git-tracked **OrcaSlicer user presets** (filament / machine / process) + bed assets, with simple export/install scripts.

This repo intentionally tracks **only portable, reproducible config** and avoids Orca caches/logs.

---

## Repo layout

```
orca-profiles/
  profiles/
    filament/
    machine/
    process/
  assets/
    bed/
      bed_220x220_with_tab.stl
      bed_220x220_grid.svg
      bed_parametric.scad
  scripts/
    windows/
      export.ps1
      install.ps1
    unix/
      export.sh
      install.sh
  README.md
  .gitignore
  .gitattributes
```

---

## What is tracked

### Presets
These folders map to the OrcaSlicer user preset directory:

- `profiles/filament/`  → `.../OrcaSlicer/user/default/filament/`
- `profiles/machine/`   → `.../OrcaSlicer/user/default/machine/`
- `profiles/process/`   → `.../OrcaSlicer/user/default/process/`

Tracked preset file types:
- `*.json`
- `*.info`

### Bed assets
Bed model + texture are tracked in:

- `assets/bed/`

Install scripts copy them to:

- `.../OrcaSlicer/assets/bed/`

Note: Orca stores `bed_custom_model` / `bed_custom_texture` as filesystem paths, so these assets must exist at the install location.

---

## Supported OS paths

### Windows
Presets:
- `%APPDATA%\OrcaSlicer\user\default\`

Bed assets:
- `%APPDATA%\OrcaSlicer\assets\bed\`

Backups:
- `%APPDATA%\OrcaSlicer\backups\`

### macOS
Presets:
- `~/Library/Application Support/OrcaSlicer/user/default/`

Bed assets:
- `~/Library/Application Support/OrcaSlicer/assets/bed/`

Backups:
- `~/Library/Application Support/OrcaSlicer/backups/`

### Linux
Presets:
- `~/.config/OrcaSlicer/user/default/`

Bed assets:
- `~/.config/OrcaSlicer/assets/bed/`

Backups:
- `~/.config/OrcaSlicer/backups/`

---

## Workflow (recommended)

### Update profiles (any machine)
1) Make changes in OrcaSlicer
2) Export from OrcaSlicer into repo (prints git diff preview):

Windows:
```powershell
.\scripts\windows\export.ps1
```

macOS/Linux:
```bash
./scripts/unix/export.sh
```

Optional: prune mode (repo mirrors Orca; removed presets are removed from repo):

Windows:
```powershell
.\scripts\windows\export.ps1 -Prune
```

macOS/Linux:
```bash
./scripts/unix/export.sh --prune
```

3) Commit and push

---

### Install profiles (any machine)
1) Pull latest changes
2) Install presets + bed assets into OrcaSlicer:

Windows:
```powershell
.\scripts\windows\install.ps1
```

macOS/Linux:
```bash
./scripts/unix/install.sh
```

To disable backups:
```bash
./scripts/unix/install.sh --no-backup
```

Windows:
```powershell
.\scripts\windows\install.ps1 -NoBackup
```

3) Launch OrcaSlicer and verify presets appear

---

## Safety notes

Note: Printer profiles are tuned to my specific hardware; use at your own risk.

- Do not run export/install while OrcaSlicer is open.
- Export scripts print a git diff preview — treat the repo as the source of truth.
- Install scripts overwrite local Orca presets (by design) but create a timestamped backup by default.
- Do not cloud-sync Orca’s full config directory unless you accept conflict risk.
