# CMakeLists.txt

cmake_minimum_required(VERSION 3.14)

project(QGIS VERSION 3.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Specify the directories for the QGIS source code
set(QGIS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/qgis)
set(QGIS_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/build)

# Include directories
include_directories(${QGIS_SOURCE_DIR}/include)

# Add subdirectories for the QGIS components
add_subdirectory(${QGIS_SOURCE_DIR}/core)
add_subdirectory(${QGIS_SOURCE_DIR}/gui)
add_subdirectory(${QGIS_SOURCE_DIR}/python)

# Set the output directories for the binaries
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${QGIS_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${QGIS_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${QGIS_BINARY_DIR}/lib)

# Find required packages
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)
find_package(GDAL REQUIRED)
find_package(PROJ REQUIRED)

# Link libraries
add_library(qgis SHARED ${QGIS_SOURCE_DIR}/src/qgis.cpp)
target_link_libraries(qgis Qt6::Core Qt6::Gui Qt6::Widgets GDAL::GDAL PROJ::PROJ)

# Install targets
install(TARGETS qgis
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib)