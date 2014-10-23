project(UbuntuSettingsComponentsQml)

find_package(Qt5Core REQUIRED)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

set(UbuntuSettingsMenusQml_SOURCES
    plugin.cpp
    signalbinder.cpp
)
add_definitions(-DUBUNTUSETTINGSCOMPONENTS_LIBRARY)

add_library(UbuntuSettingsComponentsQml MODULE
    ${UbuntuSettingsMenusQml_SOURCES}
)

qt5_use_modules(UbuntuSettingsComponentsQml Core Qml Quick)

add_usc_plugin(Ubuntu.Settings.Components 0.1 Ubuntu/Settings/Components TARGETS UbuntuSettingsComponentsQml)
