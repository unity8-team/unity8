TEMPLATE = lib

CONFIG = staticlib

QMAKE_CXXFLAGS += -std=c++0x -fPIC

INCLUDEPATH += ../libthrift

LIBS += -L../libthrift -llibthrift

SOURCES +=  src/Errors_constants.cpp \
    src/Errors_types.cpp \
    src/Limits_constants.cpp \
    src/Limits_types.cpp \
    src/NoteStore_constants.cpp \
    src/NoteStore.cpp \
    src/NoteStore_types.cpp \
    src/Types_constants.cpp \
    src/Types_types.cpp \
    src/UserStore_constants.cpp \
    src/UserStore.cpp \
    src/UserStore_types.cpp

HEADERS += src/Errors_constants.h \
    src/Errors_types.h \
    src/Limits_constants.h \
    src/Limits_types.h \
    src/NoteStore_constants.h \
    src/NoteStore.h \
    src/NoteStore_types.h \
    src/Types_constants.h \
    src/Types_types.h \
    src/UserStore_constants.h \
    src/UserStore.h \
    src/UserStore_types.h
