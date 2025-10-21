# Quick Start - Reinitialize Copied QGIS

After copying a QGIS portable installation to a new location, you **must** reinitialize it to update embedded paths.

## Three Simple Steps

### 1. Ensure `portable/` Directory Exists

Make sure the `portable/` directory was copied with your QGIS installation.

```
QGIS_Root\
  ├── bin\
  ├── apps\
  ├── portable\          ← This directory must exist
  │   ├── interactive_reinit.bat
  │   └── silent_reinit.bat
  └── ...
```

### 2. Run a Reinit Script

Open Command Prompt and navigate to your QGIS directory, then run:

**For interactive feedback** (shows progress in console):
```bat
cd /d D:\PortableQGIS
portable\interactive_reinit.bat
```

**For silent operation** (only logs to file):
```bat
cd /d D:\PortableQGIS
portable\silent_reinit.bat
```

### 3. Launch QGIS

After reinitialization completes successfully:

```bat
bin\qgis.bat
```

⚠️ **Always use `bin\qgis.bat`** - Never run `bin\qgis-bin.exe` directly!

---

## What If Something Goes Wrong?

Check the log file for details:

**Interactive mode log**:
```bat
type var\log\reinit-interactive-latest.log
```

**Silent mode log**:
```bat
type var\log\reinit-silent-latest.log
```

---

## When to Use Each Script

| Script | Best For |
|--------|----------|
| `interactive_reinit.bat` | Manual use - shows real-time progress |
| `silent_reinit.bat` | Automated deployments - minimal console output |

Both scripts perform **identical operations** - the only difference is console output verbosity.

---

## Need More Help?

See **README.md** in this directory for:
- Detailed troubleshooting guide
- Technical explanation of what gets updated
- Automated deployment examples
- Complete validation check documentation

---

**Quick reminder**: This portable QGIS installation needs reinitialization **every time** it's copied to a new location!
