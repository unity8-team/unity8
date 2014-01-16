file(GLOB_RECURSE QML_SRCS *.qml *.js)

set(reminders-app_SRCS
    main.cpp
    ${QML_SRCS}
)

add_executable(reminders-app ${reminders-app_SRCS})

qt5_use_modules(reminders-app Gui Qml Quick)

add_custom_target(reminders-app-qmlfiles ALL
    COMMAND cp -r ${CMAKE_CURRENT_SOURCE_DIR}/qml ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS ${QMLFILES}
)
