import QtQuick 2.0
import Ubuntu.Components 0.1
import Evernote 0.1

Page {
    title: note.title
    property var note

    Column {
        anchors.fill: parent
        spacing: units.gu(1)
        Button {
            width: parent.width
            text: "save"
            onClicked: {
                note.content = noteTextArea.text
                note.save();
            }
        }

        TextArea {
            id: noteTextArea
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y

            textFormat: TextEdit.RichText
            text: note.content
        }
    }
}

