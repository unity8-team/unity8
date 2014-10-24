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
    property bool isChecked: false
    property real mouseY: handle.mouseY

    signal pressAndHold()
    signal moveStarted()
    signal moveEnded()
    signal toggleFavourite()
    signal remove()
    signal clicked()

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
        color: isPersistent ? "#050505" : "red"

        Image {
            id: trashbin
            height: units.gu(2.5)
            width: height
            anchors.centerIn: parent
            source: isPersistent ? "" : "graphics/edit-delete-white.svg"
            opacity: 0.9
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
        property real dragStartThreshold: units.gu(2)
        property bool dragging: false

        property real previousMouseX
        property real previousMouseXHelper

        onPressAndHold: if (!dragging) feedDelegate.pressAndHold()
        onClicked: {
            // Clicked handled only if horizontal dragging not ongoing
            if (!dragging && !horizontalDragEndAnimation.running) {
                // reset delegate if clicked
                mouseArea.direction = Qt.RightToLeft
                horizontalDragEndAnimation.restart()

                // emit signal
                feedDelegate.clicked()
            }
        }

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
            if (dragging) {
                dragging = false
                horizontalDragEndAnimation.restart()
            }
            feedDelegate.ListView.view.interactive = true
        }
    }

    Item {
        id: topLayer
        width: parent.width
        height: parent.height
        // to smoothen out the horizontal dragging
        Behavior on x {enabled: !horizontalDragEndAnimation.running; SmoothedAnimation{duration: 50; velocity: 150; easing.type: Easing.OutQuart}}
        Rectangle {
            id: topLayerBg
            anchors.fill: parent
            color: "#f5f5f5"
        }

        Item {
            id: checkboxContainer
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            height: parent.height
            width: editModeOn ? units.gu(4) : 0
            Behavior on width {NumberAnimation{duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing}}
            visible: opacity > 000.1 && !isPersistent
            opacity: editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            clip: true

            Image {
                id: checkbox
                anchors.centerIn: parent
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
                leftMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(5)
            width: height
            opacity: 0.1
            color: "black"
            radius: units.gu(1)
        }

        Label {
            text: feedDelegate.feedName
            color: "black"
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
                rightMargin: units.gu(2)
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
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(2.5)
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
