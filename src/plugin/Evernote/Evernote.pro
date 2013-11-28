TARGET=evernoteplugin
TEMPLATE=lib
CONFIG = qt plugin
QT += qml gui xml
QMAKE_CXXFLAGS += -std=c++0x -fPIC

INCLUDEPATH += ../../../3rdParty/evernote-sdk-cpp/src/ ../../../3rdParty/libthrift

TARGET = $$qtLibraryTarget($$TARGET)
uri = Evernote

SOURCES += evernoteplugin.cpp \
    notesstore.cpp \
    userstore.cpp \
    notebooks.cpp \
    notes.cpp \
    note.cpp \
    notebook.cpp \
    jobs/fetchnotesjob.cpp \
    jobs/fetchnotebooksjob.cpp \
    jobs/fetchnotejob.cpp \
    jobs/createnotejob.cpp \
    jobs/evernotejob.cpp \
    jobs/savenotejob.cpp \
    jobs/deletenotejob.cpp \
    utils/html2enmlconverter.cpp \
    evernoteconnection.cpp \
    jobs/userstorejob.cpp \
    jobs/notesstorejob.cpp \
    jobs/fetchusernamejob.cpp

HEADERS += evernoteplugin.h \
    notesstore.h \
    userstore.h \
    notebooks.h \
    notes.h \
    note.h \
    notebook.h \
    jobs/fetchnotesjob.h \
    jobs/fetchnotebooksjob.h \
    jobs/fetchnotejob.h \
    jobs/createnotejob.h \
    jobs/evernotejob.h \
    jobs/savenotejob.h \
    jobs/deletenotejob.h \
    utils/html2enmlconverter.h \
    evernoteconnection.h \
    jobs/userstorejob.h \
    jobs/notesstorejob.h \
    jobs/fetchusernamejob.h

message(building in $$OUT_PWD)
LIBS += -L$$OUT_PWD/../../../3rdParty/evernote-sdk-cpp/ -L$$OUT_PWD/../../../3rdParty/libthrift/ -levernote-sdk-cpp -llibthrift -lssl -lcrypto

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
qmldir.files = qmldir
qmldir.path = $$installPath
target.path = $$installPath
INSTALLS += target qmldir

# Copy qml to build dir
qmldir.source = src/plugin/Evernote/qmldir
qmldir.target = .
DEPLOYMENTFOLDERS = qmldir
include(../../../deployment.pri)
