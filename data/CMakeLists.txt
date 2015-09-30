# generate desktop files
configure_file(${SHELL_APP}.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${SHELL_APP}.desktop @ONLY)
configure_file(${DASH_APP}.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${DASH_APP}.desktop @ONLY)
configure_file(${INDICATORS_CLIENT_APP}.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${INDICATORS_CLIENT_APP}.desktop @ONLY)

# install desktop files
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${SHELL_APP}.desktop
    ${CMAKE_CURRENT_BINARY_DIR}/${DASH_APP}.desktop
    ${CMAKE_CURRENT_BINARY_DIR}/${INDICATORS_CLIENT_APP}.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    )

# install dash icon
install(FILES
    unity8-dash.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/suru/apps/256
    )

install(FILES com.canonical.Unity8.gschema.xml DESTINATION ${CMAKE_INSTALL_DATADIR}/glib-2.0/schemas)
install(FILES unity8-dash.url-dispatcher DESTINATION ${CMAKE_INSTALL_DATADIR}/url-dispatcher/urls)
