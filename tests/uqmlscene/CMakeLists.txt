add_executable(uqmlscene
    ${shellapplication_MOC_SRCS}
    main.cpp
    ${CMAKE_SOURCE_DIR}/src/DebuggingController.cpp
    )

qt5_use_modules(uqmlscene Qml Quick Test DBus)

include_directories(
    SYSTEM
    ${Qt5Quick_PRIVATE_INCLUDE_DIRS}
    ${Qt5Gui_PRIVATE_INCLUDE_DIRS}
)

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/libs/UbuntuGestures
    ${libunity8-private_SOURCE_DIR}
)

target_link_libraries(uqmlscene
    ${Qt5Qml_LIBRARIES}
    ${Qt5Quick_LIBRARIES}
    UbuntuGestures
    unity8-private
    )

install(TARGETS uqmlscene
    RUNTIME DESTINATION ${SHELL_PRIVATE_LIBDIR}
    )
