
project(settings-components)

cmake_minimum_required(VERSION 2.8.9)

# Install paths
include(GNUInstallDirs)

include(FindPkgConfig)

find_package(Qt5Quick REQUIRED)
set(OUR_QT_QUICK_LIB ${Qt5Quick_LIBRARIES})

get_target_property(QMAKE_EXECUTABLE Qt5::qmake LOCATION)
exec_program(${QMAKE_EXECUTABLE} ARGS "-query QT_INSTALL_QML" OUTPUT_VARIABLE QT_IMPORTS_DIR)
file(TO_CMAKE_PATH "${QT_IMPORTS_DIR}" QT_IMPORTS_DIR)

set(OUR_QT_QUICK_INCLUDE ${Qt5Quick_INCLUDE_DIRS})
LIST(APPEND QT_PKGCONFIG_DEPENDENCIES "Qt5Quick")

set(SETTINGS_COMPONENTS_DIR ${QT_IMPORTS_DIR}/Ubuntu)

# Enable QML debugging
if(CMAKE_BUILD_TYPE MATCHES DEBUG OR CMAKE_BUILD_TYPE MATCHES "Debug")
    add_definitions(-DQT_QML_DEBUG)
endif()

find_package(Qt5Core REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5Widgets REQUIRED)
add_definitions(-DQT_NO_KEYWORDS)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

# Coverage tools
OPTION(ENABLE_COVERAGE "Build with coverage analysis support" OFF)
if(ENABLE_COVERAGE)
    message(STATUS "Using coverage flags")
    find_program(COVERAGE_COMMAND gcov)
    if(NOT COVERAGE_COMMAND)
        message(FATAL_ERROR "gcov command not found")
    endif()
    SET(CMAKE_C_FLAGS "-g -O0 -Wall -fprofile-arcs -ftest-coverage")
    SET(CMAKE_CXX_FLAGS "-g -O0 -Wall -fprofile-arcs -ftest-coverage")
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fprofile-arcs -ftest-coverage -lgcov")
    include(${CMAKE_SOURCE_DIR}/cmake/lcov.cmake)
endif()

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
               "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
               IMMEDIATE @ONLY)
add_custom_target(uninstall "${CMAKE_COMMAND}"
                  -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")

# Doc
OPTION(GENERATE_DOC "Enable qdoc generation" OFF)
if(GENERATE_DOC)
    message(STATUS "QDoc enabled.")
    find_program(QDOC_BIN qdoc)
    if(NOT QDOC_BIN)
        message(FATAL_ERROR "qdoc command not found")
    else()
        add_subdirectory(doc)
    endif()
endif()

# Install subdirectories
set(QML_DIRS
    SettingsComponents
    )

install(DIRECTORY ${QML_DIRS}
    DESTINATION ${SETTINGS_COMPONENTS_DIR}
    )

# Tests
enable_testing()

add_subdirectory(tests)
