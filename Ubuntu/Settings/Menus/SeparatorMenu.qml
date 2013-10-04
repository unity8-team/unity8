import QtQuick 2.0
import Ubuntu.Components.ListItems 0.1 as ListItem

ListItem.Empty {
    implicitHeight: units.gu(1)

    Rectangle {
        color: Qt.rgba(0.0, 0, 0, 0.15)
        anchors.fill: parent
    }
}
