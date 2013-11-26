import QtQuick 2.0
import Ubuntu.Components 0.1
import Evernote 0.1

Page {
    title: note.title
    property var note

    TextArea {
        id: noteTextArea
        anchors.fill: parent
        textFormat: TextEdit.RichText
        text: note.content
    }
}

