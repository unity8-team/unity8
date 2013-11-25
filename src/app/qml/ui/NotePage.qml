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
                print("timer triggered")
                var content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note><div><br clear=\"none\"/>"
                content = content + noteTextArea.getText(0, noteTextArea.length)
                content = content + "<br clear=\"none\"/></div><div><br clear=\"none\"/></div></en-note>"
                note.content = content
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

