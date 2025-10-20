Portable helper files for reinitializing a copied QGIS tree
=======================================================

Purpose
-------
This `portable/` directory contains a minimal, self-contained helper set you
can copy into a fresh QGIS portable installation to repair the runtime after
moving the tree to a new path or machine.

Why this is needed
-------------------
OSGeo4W-style portable QGIS uses small generated wrapper and environment
files that embed absolute paths at install/postinstall time. When the tree is
copied to a different path these generated files still point at the original
path and the QGIS binary may fail to load with DLL lookup errors (for
example: "qgis_app.dll not found").

What these helpers do
---------------------
- `reinit_portable.bat` — attempts to recreate the generated files by running
  `bin\textreplace.exe` (if present) to rewrite `bin\setup.bat`, then
  calling the generated `bin\setup.bat` or falling back to
  `etc\postinstall\setup.bat`. It also runs `bin\qgis.bat --postinstall`
  if the wrapper exists. All output is written to `var\log\reinit-<ts>.log`
  and to `var\log\reinit-latest.log`.

How to use this directory
-------------------------

1. Copy the entire `portable/` directory into the root of the QGIS tree you
  moved (so there is now `...\QGIS\portable\reinit_portable.bat`).

1. Open an elevated Command Prompt in the QGIS root and run:

```bat
portable\reinit_portable.bat
```

1. When the script completes, check `var\log\reinit-latest.log` for a
  short summary and `var\log\reinit-<timestamp>.log` for the full
  output.

Safety and limitations

- The script is conservative: it prefers `bin\setup.bat` if generated, and
  falls back to packaged `etc\postinstall\setup.bat` only when necessary.

If something goes wrong

- If the script fails, copy the generated `var\log\reinit-<timestamp>.log` and
  attach it to an issue or support request so the exact command failure can be
  diagnosed.

Authors

- Small helper set created to make portable QGIS trees relocatable without
  rebuilding or reinstalling.

Safety and limitations
----------------------
- The script is conservative: it prefers `bin\setup.bat` if generated, and
  falls back to packaged `etc\postinstall\setup.bat` only when necessary.
- If `bin\textreplace.exe` is not present in your tree the script will skip
  template patching and rely on the postinstall fallback.
- This helper does not modify system-wide configuration; it only touches
  files under the QGIS tree.

If something goes wrong
-----------------------
If the script fails, copy the generated `var\log\reinit-<timestamp>.log` and
attach it to an issue or support request so the exact command failure can be
diagnosed.

Authors
-------
Small helper set created to make portable QGIS trees relocatable without
rebuilding or reinstalling.
