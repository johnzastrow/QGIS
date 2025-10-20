Quick steps — reinitialize a copied QGIS tree
===========================================

1. Copy the `portable/` folder into the root of the QGIS tree you moved.
2. Open a Command Prompt in the QGIS root and run:

```bat
portable\reinit_portable.bat
```

3. Inspect `var\log\reinit-latest.log` for a short summary.

If you need the long log, look for `var\log\reinit-<timestamp>.log`.
