import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Gestures 0.1
import "../Components"

Showable {
    id: root
    property bool showHint: true
    property int panelWidth: units.gu(40)
    readonly property alias dragging: hideSideStageDragArea.dragging
    readonly property real progress: width / panelWidth
    property bool enableDrag: true

    width: 0
    shown: false

    Item {
        id: sideStageDragHandle
        anchors {
            right: root.left
            top: root.top
            bottom: root.bottom
        }
        width: units.gu(2)

        opacity: root.shown ? 1 : 0
        Behavior on opacity { UbuntuNumberAnimation {} }

        Image {
            anchors.centerIn: parent
            width: hideSideStageDragArea.pressed ? parent.width * 2 : parent.width
            height: parent.height
            source: "graphics/sidestage_handle@20.png"
            Behavior on width { UbuntuNumberAnimation {} }
        }
    }

    Rectangle {
        id: sideStageBackground
        anchors.fill: parent
        color: Qt.rgba(0,0,0,0.95)
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: panelWidth - units.gu(6)
        x: panelWidth/2 - width/2
        spacing: units.gu(3)
        opacity: 0.8
        visible: showHint

        Icon {
            width: units.gu(30)
            anchors.horizontalCenter: parent.horizontalCenter
            source: "graphics/sidestage_drag.svg"
            color: enabled ? Qt.rgba(1,1,1,1) : Qt.rgba(1,0,0,1)
            keyColor: Qt.rgba(1,1,1,1)
        }

        Label {
            text: "Drag using 3 fingers any application from one window to the other"
            width: parent.width
            wrapMode: Text.WordWrap
            color: enabled ? Qt.rgba(1,1,1,1) : Qt.rgba(1,0,0,1)
        }
    }

    showAnimation: NumberAnimation {
        property: "width"
        to: panelWidth
        duration: UbuntuAnimation.BriskDuration
        easing.type: Easing.OutCubic
    }

    hideAnimation: NumberAnimation {
        property: "width"
        to: 0
        duration: UbuntuAnimation.BriskDuration
        easing.type: Easing.OutCubic
    }

    DragHandle {
        id: hideSideStageDragArea
        objectName: "hideSideStageDragArea"

        direction: Direction.Leftwards
        rotation: 180
        enabled: root.shown && enableDrag
        anchors.right: root.left
        width: sideStageDragHandle.width
        height: root.height
        stretch: true

        maxTotalDragDistance: panelWidth
        autoCompleteDragThreshold: panelWidth / 2
    }

    // SideStage mouse event eater
    MouseArea {
        anchors.fill: parent
    }
}
