project(UbuntuSettingsMenusQml)

add_subdirectory(artwork)

find_package(Qt5Core REQUIRED)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

set(UbuntuSettingsMenusQml_SOURCES
    plugin.cpp
    types.h
)
add_definitions(-DUBUNTUSETTINGSCOMPONENTS_LIBRARY)

add_library(UbuntuSettingsMenusQml MODULE
    ${UbuntuSettingsMenusQml_SOURCES}
)

target_link_libraries(UbuntuSettingsMenusQml
    ${GLIB_LIBRARIES}
    ${GIO_LIBRARIES}
    ${QMENUMODEL_LDFLAGS}
    ${LIBUPSTART_LIBRARIES}
)

qt5_use_modules(UbuntuSettingsMenusQml Core Qml Quick)

add_usc_plugin(Ubuntu.Settings.Menus 0.1 Ubuntu/Settings/Menus TARGETS UbuntuSettingsMenusQml)
