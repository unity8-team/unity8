pkg_search_module(SSL openssl REQUIRED)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/3rdParty/libthrift
    ${CMAKE_SOURCE_DIR}/3rdParty/evernote-sdk-cpp/src/
    ${CMAKE_SOURCE_DIR}/src/libqtevernote
)

set(evernoteplugin_SRCS
    evernoteplugin.cpp
)

add_library(evernoteplugin MODULE
    ${evernoteplugin_SRCS}
)

target_link_libraries(evernoteplugin evernote-sdk-cpp libthrift qtevernote ${SSL_LDFLAGS})
add_dependencies(evernoteplugin qtevernote)
qt5_use_modules(evernoteplugin Gui Qml Quick)

# Copy qmldir file to build dir for running in QtCreator
if(NOT "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")
add_custom_target(evernoteplugin-qmldir ALL
    COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/qmldir ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS ${QMLFILES}
)
endif(NOT "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")

# Install plugin file
install(TARGETS evernoteplugin DESTINATION ${QT_IMPORTS_DIR}/Evernote/)
install(FILES qmldir DESTINATION ${QT_IMPORTS_DIR}/Evernote/)

