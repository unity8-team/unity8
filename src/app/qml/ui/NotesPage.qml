import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Evernote 0.1

Page {
    id: notesPage

    property alias filter: notes.filterNotebookGuid

    Notes {
        id: notes
    }

    ListView {
        anchors.fill: parent
        model: notes

        delegate: Standard {
            text: title

            onClicked: {
                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {note: notes.note(guid)})
            }
        }
    }
}
