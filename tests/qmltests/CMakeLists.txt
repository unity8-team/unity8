# add_qml_test macro
include(QmlTest)

add_subdirectory(mocks)

set(qmltest_DEFAULT_TARGETS qmluitests)
set(qmltest_DEFAULT_NO_ADD_TEST TRUE)
set(qmltest_DEFAULT_PROPERTIES ENVIRONMENT "LC_ALL=C")

set(qmltest_DEFAULT_IMPORT_PATHS
  ${CMAKE_BINARY_DIR}/plugins
  ${CMAKE_BINARY_DIR}/tests/utils/modules
)

add_qml_test(Components Calendar)
add_qml_test(Components ServerPropertySynchroniser)
add_qml_test(Components StatusIcon)

add_qml_test(Menus AccessPointMenu)
add_qml_test(Menus ButtonMenu)
add_qml_test(Menus CalendarMenu)
add_qml_test(Menus CheckableMenu)
add_qml_test(Menus EventMenu)
add_qml_test(Menus GroupedMessageMenu)
add_qml_test(Menus MediaPlayerMenu)
add_qml_test(Menus PlaybackItemMenu)
add_qml_test(Menus ProgressBarMenu)
add_qml_test(Menus ProgressValueMenu)
add_qml_test(Menus SectionMenu)
add_qml_test(Menus SimpleMessageMenu)
add_qml_test(Menus SliderMenu)
add_qml_test(Menus SnapDecisionMenu)
add_qml_test(Menus SwitchMenu)
add_qml_test(Menus UserSessionMenu)
add_qml_test(Menus TextMessageMenu)
add_qml_test(Menus TimeZoneMenu)
add_qml_test(Menus TransferMenu)

add_qml_test(Vpn VpnList)
add_qml_test(Vpn VpnEditor)
add_qml_test(Vpn VpnOpenvpnEditor)
add_qml_test(Vpn VpnPptpEditor)
add_qml_test(Vpn VpnPreviewDialogCertificateChecks)
add_qml_test(Vpn VpnPreviewDialog ENVIRONMENT NO_SSL_CERTIFICATE_CHECK=1)

add_qml_test(Fingerprint Fingerprint IMPORT_PATHS ${CMAKE_CURRENT_BINARY_DIR}/mocks)
add_qml_test(Fingerprint FingerprintSetup)
