import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: feedDelegate

    property int ownIndex
    property bool editModeOn: false
    onEditModeOnChanged: reset()
    property real mouseChange
    property real mouseYStart
    property string feedName: feedName_m //from model
    property bool isFavourite: favourite_m //from model
    property bool isPersistent: persistent_m //from model
    property real mouseY: handle.mouseY

    property bool isChecked: false

    signal pressAndHold()
    signal moveStarted()
    signal moveEnded()
    signal toggleFavourite()
    signal remove()

    width: 100
    height: 62


    function reset() {
        isChecked = false
        mouseArea.direction = Qt.RightToLeft
        horizontalDragEndAnimation.restart()
    }

    function moveTargetPressed(x, y) {
        if (isFavourite) {
            return topLayer.childAt(x,y) === handle
        } else {
            return false
        }
    }

    Rectangle {
        id: bg
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: mouseArea.maxDrag
        color: isPersistent ? "black" : "red"

        Image {
            id: trashbin
            height: units.gu(3)
            width: height
            anchors.centerIn: parent
            source: isPersistent ? "" : "graphics/edit-delete.svg"
        }

        MouseArea {
            id: bottomLayerMouseArea
            visible: !isPersistent
            enabled: visible
            anchors.fill: parent
            onClicked: feedDelegate.remove()
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.leftMargin: feedDelegate.state == "" ? 0 : maxDrag

        property int direction: Qt.LeftToRight
        property real pressedX
        property real maxDrag: units.gu(8)
        property real dragStartThreshold: units.gu(1)
        property bool dragging: false

        property real previousMouseX
        property real previousMouseXHelper

        onPressAndHold: if (!dragging) feedDelegate.pressAndHold()
        onPressed: {
            dragging = false
            pressedX = mouseX
            previousMouseX = mouseX
            previousMouseXHelper = mouseX
        }
        onMouseXChanged: {
            // detect direction
            previousMouseX = previousMouseXHelper
            previousMouseXHelper = mouseX
            if (mouseX > previousMouseX && !isPersistent) direction = Qt.LeftToRight
            else direction = Qt.RightToLeft

            if (!feedDelegate.editModeOn && Math.abs(mouseX - pressedX) >= dragStartThreshold) {
                dragging = true
                feedDelegate.ListView.view.interactive = false
            }

            if (dragging) {
                var newX
                if (feedDelegate.state == "") {
                    newX = mouseX - (pressedX + dragStartThreshold)
                    if (newX < 0) newX = 0
                    else if (newX > maxDrag) newX = maxDrag
                } else {
                    newX = maxDrag + mouseX - (pressedX - dragStartThreshold)
                    if (newX < 0) newX = 0
                    else if (newX > maxDrag) newX = maxDrag
                }

                topLayer.x = newX
            }

        }
        onReleased: {
            if (dragging) horizontalDragEndAnimation.restart()
            feedDelegate.ListView.view.interactive = true
        }
    }

    Item {
        id: topLayer
        width: parent.width
        height: parent.height

        Rectangle {
            id: topLayerBg
            anchors.fill: parent
            color: "#303030"
            border.width: 1
            border.color: "#FFFFFF"
        }

        Item {
            id: checkboxContainer
            anchors {
                left: parent.left
                leftMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(3)
            width: editModeOn ? height : 0
            Behavior on width {NumberAnimation{duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing}}
            visible: opacity > 000.1 && !isPersistent
            opacity: editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            clip: true

            Image {
                id: checkbox
                height: units.gu(3)
                width: height
                source: isChecked ? "graphics/select.svg": "graphics/select-nonselected.svg"
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: isChecked ? isChecked = false : isChecked = true
            }
        }

        Rectangle {
            id: feedIcon
            anchors {
                left: checkboxContainer.right
                leftMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(4)
            width: height
            opacity: 0.7
        }

        Label {
            text: feedDelegate.feedName
            color: "white"
            fontSize: "large"
            anchors {
                left: feedIcon.right
                leftMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }
        }

        DragHandle {
            id: handle
            anchors {
                right: parent.right
                rightMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }

            height: units.gu(3)
            width: height
            opacity: editModeOn && isFavourite ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: editModeOn && isFavourite ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
        }

        Image {
            id: favIcon
            anchors {
                right: parent.right
                rightMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(3)
            width: sourceSize.width / sourceSize.height * height
            source: isFavourite ? "graphics/starred.svg" : "graphics/non-starred.svg"
            visible: opacity > 000.1
            opacity: !editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: !editModeOn ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: feedDelegate.toggleFavourite()
            }
        }
    }


    SequentialAnimation {
        id: horizontalDragEndAnimation

        NumberAnimation {
            target: topLayer
            property: "x"
            to: mouseArea.direction == Qt.LeftToRight ? mouseArea.maxDrag : 0
            duration: UbuntuAnimation.FastDuration
            easing: UbuntuAnimation.StandardEasing
        }
        ScriptAction {
            script: mouseArea.direction == Qt.LeftToRight ? feedDelegate.state = "readyToDelete" : feedDelegate.state = ""
        }
    }

    states: [
        State {
            name: ""
        },
        State {
            name: "readyToDelete"
        }
    ]
}
