import QtQuick 2.0
import Ubuntu.Components 0.1
import Evernote 0.1

Page {

    property alias text: noteTextArea.text

    TextArea {
        id: noteTextArea
        anchors.fill: parent
        textFormat: TextEdit.RichText
    }
}

