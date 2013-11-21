TEMPLATE = subdirs
SUBDIRS = libthrift evernote-sdk-cpp

evernote-sdk-cpp.depends = libthrift
