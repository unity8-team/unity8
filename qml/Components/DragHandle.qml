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

    function persistHint(persist) {
        if (persist) {
            rollbackDragTimer.stop();
        } else if (d.persistingHint) {
           rollbackDragTimer.restart();
        }
        d.persistingHint = persist;
    }

    function resetHintRollbackTimer() {
        if (rollbackDragTimer.running && !d.persistingHint) {
            rollbackDragTimer.restart();
        }
    }

    property real hintDisplacement: 0

    property alias hintAnimationDuration: hintingAnimation.duration
    // If the drag is being rolled back, this property defines for how long it will stick around
    // on hint value before completing the rollback
    property int hintPersistencyDuration: 0
    SmoothedAnimation {
        id: hintingAnimation
        target: hintingAnimation
        property: "animatedValue"
        duration: 150
        velocity: -1
        to: Direction.isPositive(direction) ? d.startValue + hintDisplacement
                                            : d.startValue - hintDisplacement
        property real animatedValue: 0

        onAnimatedValueChanged: {
            if (running) {
                // not touching
                if (dragArea.status == DirectionalDragArea.WaitingForTouch) {
                    d.dragParent[d.targetProp] = animatedValue;
                } else {
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
        interval: hintPersistencyDuration + hintingAnimation.duration
        onTriggered: {
            d.rollbackDrag();
        }
    }

    Connections {
        target: parent.showAnimation !== undefined ? parent.showAnimation : null
        onRunningChanged: {
            if (parent.showAnimation.running) {
                d.touchesSinceFirstMovement = 0;
                d.persistingHint = false;
            }
        }
    }
    Connections {
        target: parent.hideAnimation !== undefined ? parent.hideAnimation : null
        onRunningChanged: {
            if (parent.hideAnimation.running) {
                d.touchesSinceFirstMovement = 0;
                d.persistingHint = false;
            }
        }
    }
    Connections {
        target: parent
        onShownChanged: {
            d.touchesSinceFirstMovement = 0;
            d.persistingHint = false;
        }
    }

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
        property bool persistingHint: false

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

            if (hintDisplacement == 0) {
                return step;
            }

            // if there is no rollback interval or this is the first touch;
            if (hintPersistencyDuration <= 0 || touchesSinceFirstMovement == 1) {
                // we should not go behind hintingAnimation's current value.

                if (!isParentInPositiveHintArea(step)) {
                    if (!hintingAnimation.running) {
                        // finished hinting? block changes
                        step = 0;
                    } else if (Direction.isPositive(direction) && step < 0) {
                        // block reversed direction during hinting
                        step = 0;
                    } else if (!Direction.isPositive(direction) && step > 0) {
                        // block reversed direction during hinting
                        step = 0;
                    }
                }
            }

            return step;
        }

        function isParentInPositiveHintArea(adjustment) {
            if (Direction.isPositive(direction) && dragParent[targetProp] + adjustment > hintingAnimation.to) {
                return true;
            } else if (!Direction.isPositive(direction) && dragParent[targetProp] + adjustment < hintingAnimation.to) {
                return true;
            }
            return false;
        }

        function completeDrag() {
            if (dragParent.shown) {
                d.hide();
            } else {
                d.show();
            }
        }

        function rollbackDrag() {
            if (dragParent.shown) {
                d.show();
            } else {
                d.hide();
            }
        }

        function show() {
            rollbackDragTimer.stop();
            hintingAnimation.stop();

            d.dragParent.show();
        }

        function hide() {
            rollbackDragTimer.stop();
            hintingAnimation.stop();

            d.dragParent.hide();
        }

        function hint(startRollbackTimer) {
            rollbackDragTimer.stop();
            hintingAnimation.stop();
            hintingAnimation.animatedValue = dragParent[d.targetProp];

            hintingAnimation.start();
            if (startRollbackTimer) {
                rollbackDragTimer.start();
            }
        }
    }

    property alias edgeDragEvaluator: dragEvaluator

    EdgeDragEvaluator {
        objectName: "edgeDragEvaluator"
        id: dragEvaluator
        // Effectively convert distance into the drag position projected onto the gesture direction axis
        trackedPosition: Direction.isPositive(dragArea.direction) ? sceneDistance : -sceneDistance
        maxDragDistance: maxTotalDragDistance
        direction: dragArea.direction
    }

    onDistanceChanged: {
        if (status === DirectionalDragArea.Recognized) {
            // don't go the whole distance in order to smooth out the movement
            var step = distance * 0.3;

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
                            if (hintDisplacement == 0 ||
                                d.touchesSinceFirstMovement == 1 ||
                                d.isParentInPositiveHintArea(0)) {

                                if (hintDisplacement > 0 && hintPersistencyDuration > 0) {
                                    d.hint(true);
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
                        if (hintDisplacement > 0 && hintPersistencyDuration > 0) {
                            d.hint(true);
                        } else {
                            d.rollbackDrag();
                        }
                        break;
                }
                break;

            // first touch
            case DirectionalDragArea.Undecided:
                if (d.touchesSinceFirstMovement == 0) {
                    d.startValue = d.dragParent[d.targetProp];
                }
                if (hintDisplacement > 0) {
                    d.hint(false);
                }
                d.touchesSinceFirstMovement++;

                break;
        }

        d.previousStatus = status;
    }
}
