TARGET = evernote-app
TEMPLATE = app

QT+= core qml quick

SOURCES += main.cpp \

OTHER_FILES = qml/reminders-app.qml \
    qml/ui/NotebooksPage.qml \
    qml/ui/RemindersPage.qml \
    qml/ui/NotesPage.qml \
    qml/ui/AccountSelectorPage.qml \
    qml/ui/NotePage.qml

# Copy qml to build dir for running with qtcreator
qmlfolder.source = src/app/qml
qmlfolder.target = .
DEPLOYMENTFOLDERS = qmlfolder

include(../../deployment.pri)
