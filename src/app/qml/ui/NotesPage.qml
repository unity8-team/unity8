import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Evernote 0.1

Page {
    id: notesPage

    property alias filter: notes.filterNotebookGuid

    onActiveChanged: {
        if (active) {
            print("refreshing notes")
            notes.refresh();
        }
    }

    // Just for testing
    tools: ToolbarItems {
        ToolbarButton {
            text: "add note"
            enabled: notes.filterNotebookGuid.length > 0
            onTriggered: {
                var content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note><div><br clear=\"none\"/>"
                content = content + "fobar"
                content = content + "<br clear=\"none\"/></div><div><br clear=\"none\"/></div></en-note>"
                NotesStore.createNote("Untitled", notes.filterNotebookGuid, content);
            }
        }
    }

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

            onPressAndHold: {
                notes.note(guid).remove();
            }
        }
    }
}
