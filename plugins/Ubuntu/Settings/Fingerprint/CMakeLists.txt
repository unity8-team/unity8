project(UbuntuSettingsFingerprintQml)

find_package(Qt5Core REQUIRED)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

add_definitions(-DUBUNTUSETTINGSFINGERPRINT_LIBRARY)

add_library(UbuntuSettingsFingerprintQml MODULE
    plugin.cpp
    ubuntusettingsfingerprint.cpp
)

qt5_use_modules(UbuntuSettingsFingerprintQml Core Qml Quick Svg)

add_usc_plugin(Ubuntu.Settings.Fingerprint 0.1 Ubuntu/Settings/Fingerprint TARGETS UbuntuSettingsFingerprintQml)

