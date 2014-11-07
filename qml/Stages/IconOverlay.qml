import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: iconOverlay
    property url icon
    height: units.gu(8)

    Rectangle {
        id: whiteBar
        color: "white"
        opacity: 0.85
        anchors.fill: parent
    }

    UbuntuShape {
        id: iconItem
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            margins: units.gu(1)
        }
        width: 8/7.5 * height
        color: "white"
        radius: "medium"
        borderSource: "none"
        image: Image {
            sourceSize.width: iconItem.width
            sourceSize.height: iconItem.height
            source: iconOverlay.icon
        }
    }
}
