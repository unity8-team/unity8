import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Evernote 0.1

Page {
    id: notebooksPage

    onActiveChanged: {
        if (active) {
            notebooks.refresh();
        }
    }

    Notebooks {
        id: notebooks
    }

    ListView {
        anchors.fill: parent
        model: notebooks

        delegate: Standard {
            text: name

            onClicked: {
                pagestack.push(Qt.resolvedUrl("NotesPage.qml"), {title: name, filter: guid});
            }
        }
    }
}
