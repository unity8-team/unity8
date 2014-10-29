import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: activity

    property bool running: indicator.running

    signal finished()

    function start() {
        if (!timer.running) {
            timer.interval = 1000 + Math.random()*2000
            timer.restart()
        }
    }

    // eater
    MouseArea {
        anchors.fill: parent
        visible: indicator.running
    }

    Rectangle {
        id: darkOverlay
        anchors.fill: parent
        opacity: indicator.running ? 0.2 : 0
        color: "black"
        Behavior on opacity {NumberAnimation{duration: 100}}
    }

    Timer {
        id: timer
        onTriggered: activity.finished()
    }

    ActivityIndicator {
        id: indicator
        anchors.centerIn: parent
        running: timer.running
    }
}
