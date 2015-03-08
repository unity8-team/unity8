include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/3rdParty/libthrift
    ${CMAKE_SOURCE_DIR}/3rdParty/evernote-sdk-cpp/src/
)

set(qtevernote_SRCS
    notesstore.cpp
    userstore.cpp
    notebooks.cpp
    notes.cpp
    note.cpp
    resource.cpp
    notebook.cpp
    tag.cpp
    tags.cpp
    logging.cpp
    jobs/fetchnotesjob.cpp
    jobs/fetchnotebooksjob.cpp
    jobs/fetchnotejob.cpp
    jobs/createnotejob.cpp
    jobs/evernotejob.cpp
    jobs/savenotejob.cpp
    jobs/savenotebookjob.cpp
    jobs/deletenotejob.cpp
    evernoteconnection.cpp
    jobs/userstorejob.cpp
    jobs/notesstorejob.cpp
    jobs/fetchusernamejob.cpp
    jobs/createnotebookjob.cpp
    jobs/expungenotebookjob.cpp
    jobs/fetchtagsjob.cpp
    jobs/createtagjob.cpp
    jobs/savetagjob.cpp
    resourceimageprovider.cpp
    utils/enmldocument.cpp
    utils/organizeradapter.cpp
)

add_library(qtevernote STATIC
    ${qtevernote_SRCS}
)

target_link_libraries(qtevernote evernote-sdk-cpp libthrift)
add_dependencies(qtevernote evernote-sdk-cpp libthrift)
qt5_use_modules(qtevernote Gui Qml Quick Organizer)

