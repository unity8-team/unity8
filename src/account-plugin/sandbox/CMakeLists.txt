set(ICON data/icons/evernote-sandbox.png)
set(PROVIDER_FILE data/providers/evernote-sandbox.provider)
set(SERVICE_FILE data/services/evernote-sandbox.service)
set(QML_PLUGIN_DIR ${CMAKE_INSTALL_DATADIR}/accounts/qml-plugins)

set(ICON_DIR ${CMAKE_INSTALL_DATADIR}/icons/hicolor/32x32/apps)
set(PROVIDER_DIR ${CMAKE_INSTALL_DATADIR}/accounts/providers)
set(SERVICE_DIR ${CMAKE_INSTALL_DATADIR}/accounts/services)

install(FILES ${ICON} DESTINATION ${ICON_DIR})

configure_file(${PROVIDER_FILE}.in ${CMAKE_CURRENT_BINARY_DIR}/${PROVIDER_FILE})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROVIDER_FILE}
        DESTINATION ${PROVIDER_DIR})

install(FILES ${SERVICE_FILE} DESTINATION ${SERVICE_DIR})

file(GLOB_RECURSE QML_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     qml/**.qml)
install(FILES ${QML_FILES} DESTINATION ${QML_PLUGIN_DIR}/evernote-sandbox)
