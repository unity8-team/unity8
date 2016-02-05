project(UbuntuSettingsComponentsVpn)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    PreviewDialog
    Openvpn

)

export_qmlfiles(Ubuntu.Settings.Vpn Ubuntu/Settings/Vpn DESTINATION ${QT_IMPORTS_DIR} ${ARGN})
