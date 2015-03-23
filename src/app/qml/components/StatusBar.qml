import QtQuick 2.3
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Evernote 0.1

Rectangle {
    id: root
    height: shown ? statusBarContents.height + units.gu(1) : 0
    clip: true

    property bool shown: false
    property alias iconName: icon.name
    property alias text: label.text

    Behavior on height {
        UbuntuNumberAnimation {}
    }

    ColumnLayout {
        id: statusBarContents
        anchors { left: parent.left; top: parent.top; right: parent.right }
        spacing: units.gu(1)

        Row {
            anchors { left: parent.left; right: parent.right; margins: units.gu(1) }
            spacing: units.gu(1)
            height: label.height

            Icon {
                id: icon
                height: units.gu(3)
                width: height
                color: UbuntuColors.red
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: label
                width: parent.width - x
                wrapMode: Text.WordWrap
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
