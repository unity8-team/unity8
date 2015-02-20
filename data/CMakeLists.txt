# generate desktop files
configure_file(${SHELL_APP}.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${SHELL_APP}.desktop @ONLY)
configure_file(${DASH_APP}.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${DASH_APP}.desktop @ONLY)
configure_file(unity8-greeter.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/unity8-greeter.desktop @ONLY)

# install desktop files
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${SHELL_APP}.desktop
    ${CMAKE_CURRENT_BINARY_DIR}/${DASH_APP}.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    )
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/unity8-greeter.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/lightdm/greeters
    )
install(FILES 51-unity8-greeter.conf
    DESTINATION ${CMAKE_INSTALL_DATADIR}/lightdm/lightdm.conf.d
    )
#install(FILES ${GREETER_APP}-wrapper
#    DESTINATION ${CMAKE_INSTALL_BINDIR}
#    )
#install(FILES ${GREETER_APP}-init.conf
#    DESTINATION ${CMAKE_INSTALL_DATADIR}/upstart/sessions
#    )

# install url dispatcher files
install(FILES unity8-dash.url-dispatcher DESTINATION ${CMAKE_INSTALL_DATADIR}/url-dispatcher/urls)
