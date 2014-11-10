file(GLOB_RECURSE QML_SRCS *.qml *.js)

set(reminders_SRCS
    main.cpp
    formattinghelper.cpp
    preferences.cpp
    ${QML_SRCS}
)

add_executable(reminders ${reminders_SRCS})

qt5_use_modules(reminders Gui Qml Quick)

if(NOT "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")
add_custom_target(reminders-qmlfiles ALL
    COMMAND cp -r ${CMAKE_CURRENT_SOURCE_DIR}/qml ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS ${QMLFILES}
)
endif(NOT "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")

install(DIRECTORY qml DESTINATION ${DATA_DIR})
if(CLICK_MODE)
  install(TARGETS reminders DESTINATION ${BIN_DIR})
else()
  install(TARGETS reminders RUNTIME DESTINATION bin)
endif()
