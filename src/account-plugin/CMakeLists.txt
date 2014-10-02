set(EVERNOTE_SANDBOX_CONSUMER_KEY "ubuntu")
set(EVERNOTE_SANDBOX_CONSUMER_SECRET "44f8ee81a8359500")
set(EVERNOTE_CONSUMER_KEY "canonicalis")
set(EVERNOTE_CONSUMER_SECRET "174a72ce5bffbcad")

function(EvernoteOnlineAccountSetup account_display_name account_name provider_id service_id hostname consumer_key consumer_secret)

    set(EVERNOTE_DATA_FILENAME evernote)
    set(EVERNOTE_CONSUMER_KEY ${consumer_key})
    set(EVERNOTE_CONSUMER_SECRET ${consumer_secret})

    set(EVERNOTE_ACCOUNT_DISPLAY_NAME ${account_display_name})
    set(EVERNOTE_ACCOUNT_NAME ${account_name})
    set(EVERNOTE_HOSTNAME ${hostname})

    set(EVERNOTE_PROVIDER_ID ${provider_id})
    set(EVERNOTE_SERVICE_ID ${service_id})
    set(EVERNOTE_ICON_NAME ${account_name})

    set(ICON_FILE data/icons/${EVERNOTE_ICON_NAME}.png)
    set(PROVIDER_FILE_IN data/providers/${EVERNOTE_DATA_FILENAME}.provider.in)
    set(SERVICE_FILE_IN data/services/${EVERNOTE_DATA_FILENAME}.service.in)
    set(QML_PLUGIN_FILE_IN qml/${EVERNOTE_DATA_FILENAME}/Main.qml.in)

    set(PROVIDER_FILE data/providers/${EVERNOTE_PROVIDER_ID}.provider)
    set(SERVICE_FILE data/services/${EVERNOTE_SERVICE_ID}.service)
    set(QML_PLUGIN_FILE qml/${account_name}/Main.qml)

    install(FILES ${ICON_FILE} DESTINATION ${ACCOUNT_ICON_DIR})

    configure_file(${PROVIDER_FILE_IN} ${CMAKE_CURRENT_BINARY_DIR}/${PROVIDER_FILE})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROVIDER_FILE}
            DESTINATION ${ACCOUNT_PROVIDER_DIR})

    configure_file(${SERVICE_FILE_IN} ${CMAKE_CURRENT_BINARY_DIR}/${SERVICE_FILE})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${SERVICE_FILE}
            DESTINATION ${ACCOUNT_SERVICE_DIR})

    configure_file(${QML_PLUGIN_FILE_IN} ${CMAKE_CURRENT_BINARY_DIR}/${QML_PLUGIN_FILE})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${QML_PLUGIN_FILE}
            DESTINATION ${ACCOUNT_QML_PLUGIN_DIR}/${EVERNOTE_ACCOUNT_NAME})

endfunction()

# Build and install the files for the production plugin
EvernoteOnlineAccountSetup(Evernote evernote com.ubuntu.reminders_evernote-account-plugin com.ubuntu.reminders_reminders www.evernote.com
                           ${EVERNOTE_CONSUMER_KEY} ${EVERNOTE_CONSUMER_SECRET})

if(NOT CLICK_MODE)
    # Build and install the files for the sandbox plugin
    # We're only building it as a .deb package for Jenkins, we don't need it in the click package
    EvernoteOnlineAccountSetup("Evernote Developer Sandbox" evernote-sandbox com.ubuntu.reminders_evernote-account-plugin-sandbox com.ubuntu.reminders_reminders-sandbox sandbox.evernote.com
                               ${EVERNOTE_SANDBOX_CONSUMER_KEY} ${EVERNOTE_SANDBOX_CONSUMER_SECRET})
endif(NOT CLICK_MODE)
