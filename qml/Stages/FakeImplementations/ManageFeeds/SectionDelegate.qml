import QtQuick 2.0
import Ubuntu.Components 0.1

Item {
    id: sectionDelegate

    width: parent.width
    height: units.gu(3)

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "#eaeaea"
    }

    Label {
        anchors {
            left: parent.left
            leftMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
        }
        text: section == "true" ? "Home" : "Others"
        fontSize: "small"
        color: "black"
        opacity: 1
    }

    Rectangle {
        id: divider
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.dp(1)
        color: "#d8d8d8"
    }
}
