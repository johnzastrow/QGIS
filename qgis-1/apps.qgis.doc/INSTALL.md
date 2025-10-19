# QGIS Installation Instructions

## Prerequisites
Before building QGIS, ensure you have the following installed:
- CMake
- A compatible C++ compiler (e.g., MSVC for Windows)
- Python 3.12 (shipped with QGIS)
- Qt 6 (if building with Qt6)

## Building QGIS
1. **Clone the repository**:
   ```bash
   git clone https://your-repo-url.git
   cd qgis
   ```

2. **Configure the build**:
   Open a Developer PowerShell or Command Prompt and run:
   ```bash
   cmake -S . -B build -DBUILD_WITH_QT6=ON -DWITH_QTWEBKIT=OFF -DVCPKG_TARGET_TRIPLET=x64-windows-release
   ```

3. **Build the project**:
   After configuration, build QGIS using:
   ```bash
   cmake --build build --config Release
   ```

## Running QGIS
To run QGIS, use the provided `RunQGIS.bat` script:
```bash
call "%~dp0\RunQGIS.bat"
```

This script sets up the necessary environment and launches QGIS with the specified profile and project.

## Additional Notes
- For Python development, place your scripts in the `apps/qgis/python` directory.
- QGIS plugins should be placed in the `apps/qgis/plugins` directory.
- Refer to `bin/qgis.bat` for environment variable settings and adjustments.

## Troubleshooting
If you encounter issues during the build or run process, check the following:
- Ensure all prerequisites are installed and correctly configured.
- Review the output logs for any errors or warnings.
- Consult the QGIS community for support and guidance.