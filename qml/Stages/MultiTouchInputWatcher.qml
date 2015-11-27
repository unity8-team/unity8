import QtQuick 2.0
import Utils 0.1

InputWatcher {
    id: root
    eatMoveEvents: touchPoints.length === targetTouchPoints

    property int targetTouchPoints: 1
    property bool multiTouchDragging: false
    property bool multiTouchPressed_: false

    signal multiTouchPressed
    signal multiTouchReleased
    signal multiTouchClicked
    signal multiTouchDropped

    property var releaseTimer: Timer {
        interval: 1000
        onTriggered: {
            if (multiTouchDragging) {
                root.multiTouchDropped();
            }
            multiTouchDragging = false;
            multiTouchPressed_ = false;
            root.multiTouchReleased();
        }
    }

    onMultiTouchPressed_Changed: {
        if (multiTouchPressed_) {
            root.multiTouchPressed();
        } else {
            root.multiTouchReleased();
        }
    }
    onTargetChanged: {
        multiTouchDragging = false;
        multiTouchPressed_ = false;
    }

    onPressed: {
        if (touchPoints.length === targetTouchPoints) {
            releaseTimer.stop();
            multiTouchPressed_ = true;
        } else {
            multiTouchPressed_ = false;
        }
    }
    onDraggingChanged: {
        if (multiTouchPressed_ && dragging) {
            multiTouchDragging = true;
        }
    }
    onReleased: {
        if (touchPoints.length === 0) {
            releaseTimer.start();
        }
    }
    onClicked: {
        if (touchPoints.length === 0) {
            if (multiTouchPressed_) {
                root.multiTouchClicked();
            }
            multiTouchDragging = false;
            multiTouchPressed_ = false;
        }
    }
}
