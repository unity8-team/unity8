# export_qmlplugin macro
include(Plugins)

project(UbuntuSettingsMenusQml)

add_subdirectory(artwork)

find_package(Qt5Core REQUIRED)
find_package(Qt5Quick REQUIRED)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

set(SettingsComponentsQml_SOURCES
    plugin.cpp
)
add_definitions(-DUBUNTUSETTINGSCOMPONENTS_LIBRARY)

add_library(UbuntuSettingsMenusQml SHARED
    ${SettingsComponentsQml_SOURCES}
)

target_link_libraries(UbuntuSettingsMenusQml
    ${GLIB_LIBRARIES}
    ${GIO_LIBRARIES}
    ${QMENUMODEL_LDFLAGS}
    ${LIBUPSTART_LIBRARIES}
)

qt5_use_modules(UbuntuSettingsMenusQml Core Qml Quick)

# export the qmldir, *.qml files.
export_qmlfiles(Ubuntu.Settings.Menus Ubuntu/Settings/Menus)

# export the qmltypes and plugin files
export_qmlplugin(Ubuntu.Settings.Menus 0.1 Ubuntu/Settings/Menus TARGETS UbuntuSettingsMenusQml)
