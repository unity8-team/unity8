import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Gestures 0.1
import "../Components"

Showable {
    id: root
    readonly property alias dragging: hideSideStageDragArea.dragging
    property int panelWidth: units.gu(40)
    readonly property real progress: width / panelWidth

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
        enabled: root.shown
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
