import QtQuick 2.0
import Ubuntu.Components 0.1
import "Math.js" as MathLocal

MouseArea {
    id: draggingArea

    property int orientation: Qt.Vertical
    property bool dragging
    property real dragVelocity: 0
    property real dragValue: (orientation == Qt.Vertical ? (mouseY - __pressedPosition.y)
                                                            : (mouseX - __pressedPosition.x))
    property real lateralPosition: orientation == Qt.Horizontal ? MathLocal.clamp(mouseY, 0, height) : MathLocal.clamp(mouseX, 0, width)
    property point __pressedPosition: Qt.point(0, 0)
    property var __dragEvents: []
    property bool clickValidated: true
    property bool zeroVelocityCounts: false


    signal dragStart
    signal dragEnd

    onDragValueChanged: {
        if (dragValue != 0 && pressed) {
            dragging = true
        }
    }

    onDraggingChanged: {
        if (dragging) {
            dragStart()
        }
        else {
            dragEnd()
        }
    }

    function updateSpeed() {
        var totalSpeed = 0
        for (var i=0; i<__dragEvents.length; i++) {
            totalSpeed += __dragEvents[i][3]
        }

        if (zeroVelocityCounts || Math.abs(totalSpeed) > 0.001) {
            dragVelocity = totalSpeed / __dragEvents.length * 1000
        }
    }

    function cullOldDragEvents(currentTime) {
        // cull events older than 50 ms but always keep the latest 2 events
        for (var numberOfCulledEvents=0; numberOfCulledEvents<__dragEvents.length-2; numberOfCulledEvents++) {
            // __dragEvents[numberOfCulledEvents][0] is the dragTime
            if (currentTime - __dragEvents[numberOfCulledEvents][0] <= 50) break
        }

        __dragEvents.splice(0, numberOfCulledEvents)
    }

    function getEventSpeed(currentTime, event) {
        if (__dragEvents.length != 0) {
            var lastDrag = __dragEvents[__dragEvents.length-1]
            var duration = Math.max(1, currentTime - lastDrag[0])
            if (orientation == Qt.Vertical) {
                return (event.y - lastDrag[2]) / duration
            } else {
                return (event.x - lastDrag[1]) / duration
            }
        } else {
            return 0
        }
    }

    function pushDragEvent(event) {
        var currentTime = new Date().getTime()
        __dragEvents.push([currentTime, event.x, event.y, getEventSpeed(currentTime, event)])
        cullOldDragEvents(currentTime)
        updateSpeed()
    }

    onPositionChanged: {
        if (dragging) {
            pushDragEvent(mouse)
        }
        if (!draggingArea.containsMouse)
            clickValidated = false
    }

    onPressed: {
        __pressedPosition = Qt.point(mouse.x, mouse.y)
        __dragEvents = []
        pushDragEvent(mouse)
        clickValidated = true
    }

    onReleased: {
        dragging = false
        __pressedPosition = Qt.point(mouse.x, mouse.y)
    }
}
