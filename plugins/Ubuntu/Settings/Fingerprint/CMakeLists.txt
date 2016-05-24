project(UbuntuSettingsFingerprintQml)

find_package(Qt5Svg REQUIRED)
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)
add_definitions(-DUBUNTUSETTINGSFINGERPRINT_LIBRARY)
QT5_ADD_RESOURCES(assets assets.qrc)
add_library(UbuntuSettingsFingerprintQml MODULE
    plugin.cpp
    ubuntusettingsfingerprint.cpp
    fingerprintvisual.cpp
    fingerprintvisualprovider.cpp
    ${assets}
)
target_link_libraries(UbuntuSettingsFingerprintQml Qt5::Core Qt5::Quick Qt5::Svg)
qt5_use_modules(UbuntuSettingsFingerprintQml Core Qml Quick Svg)
add_usc_plugin(Ubuntu.Settings.Fingerprint 0.1 Ubuntu/Settings/Fingerprint TARGETS UbuntuSettingsFingerprintQml)
