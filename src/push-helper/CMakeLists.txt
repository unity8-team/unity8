pkg_search_module(SSL openssl REQUIRED)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/3rdParty/libthrift
    ${CMAKE_SOURCE_DIR}/3rdParty/evernote-sdk-cpp/src/
    ${CMAKE_SOURCE_DIR}/src/libqtevernote
)


set(push-helper_SRCS
    main.cpp
    core.cpp
)

add_executable(push-helper ${push-helper_SRCS})
add_dependencies(push-helper qtevernote)
target_link_libraries(push-helper evernote-sdk-cpp libthrift qtevernote pthread ${SSL_LDFLAGS})

qt5_use_modules(push-helper Core Organizer)

if(CLICK_MODE)
  install(TARGETS push-helper DESTINATION ${BIN_DIR})
else()
  install(TARGETS push-helper RUNTIME DESTINATION bin)
endif()
