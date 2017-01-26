include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/plugins/LightDM
    ${CMAKE_SOURCE_DIR}/plugins/Utils
    ${CMAKE_SOURCE_DIR}/tests/mocks/liblightdm
    )

include_directories(
    SYSTEM
    ${GLIB_INCLUDE_DIRS}
    ${LIBLIGHTDM_INCLUDE_DIRS}
    )

link_libraries(
    LightDM-qml
    MockLightDM
    )

# DBusTest
add_executable(GreeterDBusTestExec
    dbus.cpp
    ${CMAKE_SOURCE_DIR}/plugins/LightDM/Greeter.cpp
    ${CMAKE_SOURCE_DIR}/plugins/LightDM/PromptsModel.cpp
    )
qt5_use_modules(GreeterDBusTestExec Core DBus Quick Test)
set_target_properties(GreeterDBusTestExec PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${SHELL_INSTALL_QML}/mocks/liblightdm")
install(TARGETS GreeterDBusTestExec
    DESTINATION "${SHELL_PRIVATE_LIBDIR}/tests/plugins/LightDM"
    )
install(FILES greeter.qml
    DESTINATION "${SHELL_APP_DIR}/tests/plugins/LightDM"
    )
add_unity8_uitest(GreeterDBus dbus-test-runner
    ARG_PREFIX "--parameter"
    ARGS --task $<TARGET_FILE:GreeterDBusTestExec>
    DEPENDS LightDM-qml;MockLightDM
    )

# SessionsModelTest
add_executable(GreeterSessionsModelTestExec
    sessionsmodel.cpp
    ${CMAKE_SOURCE_DIR}/plugins/LightDM/SessionsModel.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/unitysortfilterproxymodelqml.cpp
    )
qt5_use_modules(GreeterSessionsModelTestExec Core Test)
install(TARGETS GreeterSessionsModelTestExec
    DESTINATION "${SHELL_PRIVATE_LIBDIR}/tests/plugins/LightDM"
    )
add_unity8_unittest(GreeterSessions GreeterSessionsModelTestExec
    DEPENDS LightDM-qml;MockLightDM
    )

# UsersModelTest
add_executable(GreeterUsersModelTestExec
    usersmodel.cpp
    ${CMAKE_SOURCE_DIR}/plugins/LightDM/Greeter.cpp
    ${CMAKE_SOURCE_DIR}/plugins/LightDM/PromptsModel.cpp
    ${CMAKE_SOURCE_DIR}/plugins/LightDM/UsersModel.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/unitysortfilterproxymodelqml.cpp
    )
qt5_use_modules(GreeterUsersModelTestExec Core Test)
set_target_properties(GreeterUsersModelTestExec PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${SHELL_INSTALL_QML}/mocks/liblightdm")
install(TARGETS GreeterUsersModelTestExec
    DESTINATION "${SHELL_PRIVATE_LIBDIR}/tests/plugins/LightDM"
    )
add_unity8_unittest(GreeterUsers GreeterUsersModelTestExec
    DEPENDS LightDM-qml;MockLightDM
    )

# PromptsModelTest
add_executable(GreeterPromptsModelTestExec
    promptsmodel.cpp
    ${CMAKE_SOURCE_DIR}/plugins/LightDM/Greeter.cpp
    ${CMAKE_SOURCE_DIR}/plugins/LightDM/PromptsModel.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Utils/unitysortfilterproxymodelqml.cpp
    )
qt5_use_modules(GreeterPromptsModelTestExec Core Test)
install(TARGETS GreeterPromptsModelTestExec
    DESTINATION "${SHELL_PRIVATE_LIBDIR}/tests/plugins/LightDM"
    )
add_unity8_unittest(GreeterPrompts GreeterPromptsModelTestExec
    DEPENDS LightDM-qml;MockLightDM
    )
