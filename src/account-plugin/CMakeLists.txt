function(EvernoteOnlineAccountSetup account_display_name account_name hostname consumer_key consumer_secret)

    set(EVERNOTE_DATA_FILENAME evernote)
    set(EVERNOTE_CONSUMER_KEY ${consumer_key})
    set(EVERNOTE_CONSUMER_SECRET ${consumer_secret})

    set(EVERNOTE_ACCOUNT_DISPLAY_NAME ${account_display_name})
    set(EVERNOTE_ACCOUNT_NAME ${account_name})
    set(EVERNOTE_HOSTNAME ${hostname})

    set(EVERNOTE_PROVIDER_ID ${account_name})
    set(EVERNOTE_SERVICE_ID ${account_name})
    set(EVERNOTE_ICON_NAME ${account_name})

    set(ICON_FILE data/icons/${account_name}.png)
    set(PROVIDER_FILE_IN data/providers/${EVERNOTE_DATA_FILENAME}.provider.in)
    set(SERVICE_FILE_IN data/services/${EVERNOTE_DATA_FILENAME}.service.in)
    set(QML_PLUGIN_FILE_IN qml/${EVERNOTE_DATA_FILENAME}/Main.qml.in)

    set(PROVIDER_FILE data/providers/${account_name}.provider)
    set(SERVICE_FILE data/services/${account_name}.service)
    set(QML_PLUGIN_FILE qml/${account_name}/Main.qml)

    set(ICON_DIR ${CMAKE_INSTALL_DATADIR}/icons/hicolor/32x32/apps)
    set(PROVIDER_DIR ${CMAKE_INSTALL_DATADIR}/accounts/providers)
    set(SERVICE_DIR ${CMAKE_INSTALL_DATADIR}/accounts/services)
    set(QML_PLUGIN_DIR ${CMAKE_INSTALL_DATADIR}/accounts/qml-plugins)

    install(FILES ${ICON_FILE} DESTINATION ${ICON_DIR})

    configure_file(${PROVIDER_FILE_IN} ${CMAKE_CURRENT_BINARY_DIR}/${PROVIDER_FILE})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROVIDER_FILE}
            DESTINATION ${PROVIDER_DIR})

    configure_file(${SERVICE_FILE_IN} ${CMAKE_CURRENT_BINARY_DIR}/${SERVICE_FILE})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${SERVICE_FILE}
            DESTINATION ${SERVICE_DIR})

    configure_file(${QML_PLUGIN_FILE_IN} ${CMAKE_CURRENT_BINARY_DIR}/${QML_PLUGIN_FILE})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${QML_PLUGIN_FILE}
            DESTINATION ${QML_PLUGIN_DIR}/${EVERNOTE_ACCOUNT_NAME})

endfunction()

# Build and install the files for the production plugin
EvernoteOnlineAccountSetup(Evernote evernote www.evernote.com
                           ${EVERNOTE_CONSUMER_KEY} ${EVERNOTE_CONSUMER_SECRET})

# Build and install the files for the sandbox plugin
EvernoteOnlineAccountSetup("Evernote Developer Sandbox" evernote-sandbox sandbox.evernote.com
                           ${EVERNOTE_SANDBOX_CONSUMER_KEY} ${EVERNOTE_SANDBOX_CONSUMER_SECRET})
