file(GLOB_RECURSE QML_SRCS *.qml *.js)

set(reminders_SRCS
    main.cpp
    ${QML_SRCS}
)

add_executable(reminders ${reminders_SRCS})

qt5_use_modules(reminders Gui Qml Quick)

add_custom_target(reminders-qmlfiles ALL
    COMMAND cp -r ${CMAKE_CURRENT_SOURCE_DIR}/qml ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS ${QMLFILES}
)

install(DIRECTORY qml DESTINATION ${DATA_DIR})
