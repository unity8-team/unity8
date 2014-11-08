include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/3rdParty/libthrift
)

SET(evernote-sdk-cpp_SRCS
    src/Errors_constants.cpp
    src/Errors_types.cpp
    src/Limits_constants.cpp
    src/Limits_types.cpp
    src/NoteStore_constants.cpp
    src/NoteStore.cpp
    src/NoteStore_types.cpp
    src/Types_constants.cpp
    src/Types_types.cpp
    src/UserStore_constants.cpp
    src/UserStore.cpp
    src/UserStore_types.cpp
)

add_library(evernote-sdk-cpp STATIC ${evernote-sdk-cpp_SRCS})

