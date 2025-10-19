# QGIS Project

This repository contains the QGIS project, a powerful open-source geographic information system (GIS) application. Below is an overview of the project's structure and instructions for building and running QGIS.

## Project Structure

- **bin/**: Contains executable files and batch scripts for running QGIS.
  - `qgis.bat`: Environment wrapper for setting up necessary environment variables.
  - `RunQGIS.bat`: Script to launch QGIS with the correct environment setup.
  - `reinit.bat`: Script to reinitialize the QGIS environment.

- **apps/**: Contains application-specific files.
  - **Python312/**: Shipped Python runtime for QGIS.
  - **qgis/**: Contains Python packages and plugins for QGIS.
    - **python/**: Directory for PyQGIS packages.
    - **plugins/**: Directory for QGIS plugins.

- **setup/**: Contains installation and setup scripts for QGIS.

- **postinstall/**: Contains scripts that run after QGIS installation.

- **vcpkg/**: Contains the vcpkg dependency manifest.
  - `vcpkg.json`: Lists the dependencies required for the project.

- **CMakeLists.txt**: Configuration file for CMake to build the QGIS project.

- **apps/qgis/doc/**: Documentation for building and running QGIS.
  - `INSTALL.md`: Detailed instructions for building and running QGIS.

## Getting Started

To get started with QGIS, follow these steps:

1. **Clone the Repository**: Clone this repository to your local machine.
2. **Set Up Environment**: Use `RunQGIS.bat` to set up the environment and launch QGIS.
3. **Build QGIS**: Follow the instructions in `INSTALL.md` to build QGIS from source if needed.

## Contributing

Contributions to the QGIS project are welcome! Please follow the guidelines in the repository for submitting changes or improvements.

## License

This project is licensed under the GNU General Public License. See the LICENSE file for more details.