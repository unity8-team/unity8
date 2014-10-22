import QtQuick 2.0

Item {
    id: handle

    property alias mouseY: dragArea.mouseY

    Image {
        id: grip
        source: "graphics/grip.png"
        sourceSize.width: parent.width / 3
        sourceSize.height: parent.height / 3
        anchors.fill: parent
        fillMode: Image.Tile
        opacity: 0.6
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -units.gu(1)
        visible: false
        property real initialY: -1
        onPressed: {
            mouseYStart = mouseY
            feedDelegate.opacity = 0
            feedDelegate.moveStarted()
        }
        onMouseYChanged: {
            feedDelegate.mouseChange = mouseY - mouseYStart
        }

        onReleased: {
            mouseYStart = -1
            feedDelegate.moveEnded()
            feedDelegate.opacity = 1
            feedDelegate.mouseChange = 0
        }
    }
}
