/*
 * Copyright (C) 2013, 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Gestures 0.1

/*
 Put a DragHandle inside a Showable to enable the user to drag it from that handle.
 Main use case is to drag fullscreen Showables into the screen or off the screen.

 This example shows a DragHandle placed on the right corner of a Showable, used
 to slide it away, off the screen.

  Showable {
    x: 0
    y: 0
    width: ... // screen width
    height: ... // screen height
    shown: true
    ...
    DragHandle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: units.gu(2)

        direction: DirectionalDragArea::Leftwards
    }
  }

 */
EdgeDragArea {
    id: dragArea
    objectName: "dragHandle"

    // Disable most of the gesture recognition parameters by default when hinting is used as
    // it conflicts with the hinting idea.
    // The only part we keep in this situation is that it must be a single-finger gesture.
    distanceThreshold: hintDisplacement > 0 ? 0 : defaultDistanceThreshold
    maxSilenceTime: hintDisplacement > 0 ? 60*60*1000 : defaultMaxSilenceTime
    maxDeviation: hintDisplacement > 0 ? 999999 : defaultMaxDeviation

    property bool stretch: false

    property alias autoCompleteDragThreshold: dragEvaluator.dragThreshold

    // How far you can drag
    property real maxTotalDragDistance: {
        if (stretch) {
            0; // not enough context information to set a sensible default
        } else {
            Direction.isHorizontal(direction) ? parent.width : parent.height;
        }
    }

    function resetHintRollbackTimer() {
        if (rollbackDragTimer.running) {
            rollbackDragTimer.restart();
        }
    }

    property real hintDisplacement: 0

    property int hintAnimationDuration: 150
    // If the drag is being rolled back, this property defines for how long it will stick around
    // on hint value before completing the rollback
    property int hintPersistencyDuration: 0

    onHintPersistencyDurationChanged: {
        var persist = hintPersistencyDuration < 0;
        if (persist) {
            rollbackDragTimer.stop();
        } else {
            rollbackDragTimer.hintPersistencyInterval = hintPersistencyDuration;
            if (d.persistingHint && state == "hinting") {
                rollbackDragTimer.restart();
            }
        }
        d.persistingHint = persist;
    }

    SmoothedAnimation {
        id: hintingAnimation
        target: hintingAnimation
        property: "animatedValue"
        duration: hintAnimationDuration
        velocity: -1
        to: Direction.isPositive(direction) ? d.startValue + hintDisplacement
                                            : d.startValue - hintDisplacement
        property real animatedValue: 0

        onAnimatedValueChanged: {
            if (running) {
                // not touching
                if (dragArea.status == DirectionalDragArea.WaitingForTouch) {
                    d.dragParent[d.targetProp] = animatedValue;
                } else if (d.touchesSinceFirstMovement == 1 && !d.movedPastHintDisplacement) {
                    if (Direction.isPositive(direction)) {
                        if (d.dragParent[d.targetProp] < animatedValue) {
                            d.dragParent[d.targetProp] = animatedValue;
                        }
                    } else {
                        if (d.dragParent[d.targetProp] > animatedValue) {
                            d.dragParent[d.targetProp] = animatedValue;
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: rollbackDragTimer
        property int hintPersistencyInterval: hintPersistencyDuration
        interval: hintPersistencyInterval + hintAnimationDuration

        onTriggered: {
            d.rollbackDrag();
        }
    }

    Connections {
        target: parent.showAnimation !== undefined ? parent.showAnimation : null
        onRunningChanged: {
            if (parent.showAnimation.running) {
                dragArea.state = "shown";
            }
        }
    }
    Connections {
        target: parent.hideAnimation !== undefined ? parent.hideAnimation : null
        onRunningChanged: {
            if (parent.hideAnimation.running) {
                dragArea.state = "hidden";
            }
        }
    }
    Connections {
        target: parent
        onShownChanged: {
            dragArea.state = parent.shown ? "shown" : "hidden";
        }
    }

    state: parent.shown ? "shown" : "hidden";

    states: [
        State {
            name: "hidden"
            StateChangeScript { script: {
                rollbackDragTimer.stop();
                hintingAnimation.stop();
                d.touchesSinceFirstMovement = 0;
                d.movedPastHintDisplacement = false;
            }}
        },
        State {
            name: "dragging"
            StateChangeScript { script: {
                rollbackDragTimer.stop();
                hintingAnimation.stop();

                // mark the offset when we start dragging.
                d.dragDistanceOffset = d.parentProgress;
            }}
        },
        State {
            name: "hinting"
            StateChangeScript { script: {
                rollbackDragTimer.stop();
                hintingAnimation.stop();

                hintingAnimation.animatedValue = d.dragParent[d.targetProp];
                hintingAnimation.start();
            }}
        },
        State {
            name: "shown"
            StateChangeScript { script: {
                rollbackDragTimer.stop();
                hintingAnimation.stop();
                d.touchesSinceFirstMovement = 0;
                d.movedPastHintDisplacement = false;
            }}
        }
    ]

    // Private stuff
    QtObject {
        id: d
        property var previousStatus: DirectionalDragArea.WaitingForTouch
        property real startValue
        property real minValue: Direction.isPositive(direction) ? startValue
                                                                : startValue - maxTotalDragDistance
        property real maxValue: Direction.isPositive(direction) ? startValue + maxTotalDragDistance
                                                                : startValue

        property var dragParent: dragArea.parent
        property int touchesSinceFirstMovement: 0
        property bool movedPastHintDisplacement: false
        property bool persistingHint: false

        property real dragDistanceOffset: 0
        property real parentProgress: {
            if (stretch) {
                if (Direction.isPositive(direction)) {
                    return (Direction.isHorizontal(direction) ? parent.width : parent.height);
                } else {
                    return maxTotalDragDistance - (Direction.isHorizontal(direction) ? parent.width : parent.height);
                }
            } else {
                if (Direction.isPositive(direction)) {
                    return Direction.isHorizontal(direction) ? parent.width + parent.x : parent.height + parent.y;
                } else {
                    return Direction.isHorizontal(direction) ? -parent.x : -parent.y;
                }
            }
        }

        // The property of DragHandle's parent that will be modified
        property string targetProp: {
            if (stretch) {
                Direction.isHorizontal(direction) ? "width" : "height";
            } else {
                Direction.isHorizontal(direction) ? "x" : "y";
            }
        }

        function limitMovement(inputStep) {
            var targetValue = MathUtils.clamp(dragParent[targetProp] + inputStep, minValue, maxValue);
            var step = targetValue - dragParent[targetProp];

            if (hintDisplacement == 0 || touchesSinceFirstMovement > 1) {
                return step;
            }

            if (!isParentBeyondHintDisplacement(step)) {
                // reject backward movement if havent gone past hint displacement yet.
                if (Direction.isPositive(direction)) {
                    if (step < 0 &&
                        d.dragParent[d.targetProp] + step < hintingAnimation.to &&
                        !d.movedPastHintDisplacement) {
                        step = 0;
                    }
                } else {
                    if (step > 0 &&
                        d.dragParent[d.targetProp] + step > hintingAnimation.to &&
                        !d.movedPastHintDisplacement) {
                        step = 0;
                    }
                }
            }

            return step;
        }

        function isParentBeyondHintDisplacement(adjustment) {
            if (Direction.isPositive(direction) && dragParent[targetProp] + adjustment > hintingAnimation.to) {
                return true;
            } else if (!Direction.isPositive(direction) && dragParent[targetProp] + adjustment < hintingAnimation.to) {
                return true;
            }
            return false;
        }

        function completeDrag() {
            if (dragParent.shown) {
                d.dragParent.hide();
            } else {
                d.dragParent.show();
            }
        }

        function rollbackDrag() {
            if (dragParent.shown) {
                d.dragParent.show();
            } else {
                d.dragParent.hide();
            }
        }
    }

    property alias edgeDragEvaluator: dragEvaluator

    EdgeDragEvaluator {
        objectName: "edgeDragEvaluator"
        id: dragEvaluator
        // Effectively convert distance into the drag position projected onto the gesture direction axis
        trackedPosition: d.dragDistanceOffset +
                         Direction.isPositive(dragArea.direction) ? sceneDistance : -sceneDistance

        maxDragDistance: maxTotalDragDistance
        direction: dragArea.direction
    }

    onDistanceChanged: {
        if (status === DirectionalDragArea.Recognized) {
            // don't go the whole distance in order to smooth out the movement
            var step = distance * 0.3;

            if (!d.movedPastHintDisplacement && hintDisplacement) {
                if (Direction.isPositive(direction)) {
                    if (d.dragParent[d.targetProp] + step > hintingAnimation.to) {
                        d.movedPastHintDisplacement = true;
                        // not hinting anymore.
                        dragArea.state = "dragging";
                    }
                } else {
                    if (d.dragParent[d.targetProp] + step <  hintingAnimation.to) {
                        d.movedPastHintDisplacement = true;
                        // not hinting anymore.
                        dragArea.state = "dragging";
                    }
                }
            }

            step = d.limitMovement(step);

            d.dragParent[d.targetProp] += step;
        }
    }

    onStatusChanged: {

        switch (status) {
            // release
            case DirectionalDragArea.WaitingForTouch:
                switch (d.previousStatus) {
                    // we released the touch after previously recognising the touch event
                    case DirectionalDragArea.Recognized:
                        if (dragEvaluator.shouldAutoComplete()) {
                            d.completeDrag();
                        } else {
                            if (hintDisplacement > 0 && hintPersistencyDuration !== 0) {
                                // If dropped when we're in first touch, and we haven't moved past the hint displacement area before
                                // Or, if dropped when were past the hint displacement.
                                if ((d.touchesSinceFirstMovement == 1 && !d.movedPastHintDisplacement) || d.isParentBeyondHintDisplacement(0)) {
                                    state = "hinting";
                                    if (hintPersistencyDuration > 0) {
                                        rollbackDragTimer.start();
                                    }
                                } else {
                                    d.rollbackDrag();
                                }
                            } else {
                                d.rollbackDrag();
                            }
                        }
                        break;

                    // we released the touch after not yet recognising the touch event
                    case DirectionalDragArea.Undecided:
                        if (hintDisplacement > 0 && hintPersistencyDuration !== 0) {
                            state = "hinting";
                            if (hintPersistencyDuration > 0) {
                                rollbackDragTimer.start();
                            }
                        } else {
                            d.rollbackDrag();
                        }
                        break;
                }
                break;

            // first touch
            case DirectionalDragArea.Undecided:
                state = "dragging";

                if (d.touchesSinceFirstMovement == 0) {
                    d.startValue = d.dragParent[d.targetProp];

                    if (hintDisplacement > 0) {
                        state = "hinting";
                    }
                }

                d.touchesSinceFirstMovement++;
                break;
        }

        d.previousStatus = status;
    }
}
