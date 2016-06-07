/*
 * Copyright (C) 2016 Canonical, Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: root

    property bool enabled: false
    property bool horizontal: false
    property bool variableVelocity: true
    property int delay: 2 // ms delay between scrolls
    property real areaLength: units.gu(5)
    property real maxStep: units.dp(2)
    property Flickable flickable

    function startScrolling(positiveDirection) {
        progressiveScrollingTimer.scrollPositiveDirection = positiveDirection;
        progressiveScrollingTimer.start();
    }

    function stopScrolling() {
        progressiveScrollingTimer.stop();
    }

    /* If enabled, increase step size based on pointer location
     * This makes scrolling change speed depending on how close the pointer
     * is to the upper/lower limit
     */
    function stepSize() {
        if (!root.variableVelocity) return root.maxStep;
        var delta;
        var step;
        if (!progressiveScrollingTimer.scrollPositiveDirection) {
            delta = d.relevantMouseAxis - d.lowerLimit;
            delta = delta / root.areaLength;
            step = Math.abs(delta * root.maxStep);
        } else {
            delta = d.relevantMouseAxis - d.upperLimit;
            delta = delta / root.areaLength
            step = Math.abs(delta * root.maxStep)
        }

        return step;
    }

    QtObject {
        id: d

        readonly property bool atRelevantContentAxisBeginning: root.horizontal ?
            root.flickable.atXBeginning : root.flickable.atYBeginning

        readonly property bool atRelevantContentAxisEnd: root.horizontal ?
            root.flickable.atXEnd : root.flickable.atYEnd

        // lower and upper are in terms of raw coordinates and not top/bottom of a list
        readonly property real lowerLimit: root.areaLength
        readonly property real upperLimit: {
            if (root.horizontal) {
                return (root.flickable.visibleArea.widthRatio *
                        root.flickable.contentWidth) - root.areaLength;
            } else {
                return (root.flickable.visibleArea.heightRatio *
                        root.flickable.contentHeight) - root.areaLength;
            }
        }

        property real relevantContentAxis
        property real relevantMouseAxis
    }

    Timer {
        id: progressiveScrollingTimer

        property bool scrollPositiveDirection: true
        readonly property real listEnd: {
            if (root.horizontal) {
                return (1 - root.flickable.visibleArea.widthRatio) *
                        root.flickable.contentWidth;
            } else {
                return (1 - root.flickable.visibleArea.heightRatio) *
                        root.flickable.contentHeight;
            }
        }
        interval: root.delay
        repeat: true
        running: false

        onTriggered: {
            if (!scrollPositiveDirection && !d.atRelevantContentAxisBeginning) {
                if (d.relevantContentAxis > root.stepSize()) {
                    d.relevantContentAxis -= root.stepSize();
                } else {
                    d.relevantContentAxis = 0;
                    stop();
                }
            } else if (scrollPositiveDirection && !d.atRelevantContentAxisEnd) {
                if (listEnd - d.relevantContentAxis > root.stepSize()) {
                    d.relevantContentAxis += root.stepSize();
                } else {
                    d.relevantContentAxis = listEnd;
                    stop();
                }
            }
        }
    }

    property alias animationProperty: d.relevantContentAxis
    Behavior on animationProperty { UbuntuNumberAnimation{}  }

    Binding {
        target: root.flickable
        property: root.horizontal ? "contentX" : "contentY"
        value: d.relevantContentAxis
    }

    Mouse.onPositionChanged: {
        if (!root.enabled) return;

        // This synchronizes the bindings as scrolling from the middle of the list
        // can sometimes break
        if (root.horizontal) d.relevantContentAxis = root.flickable.contentX
        else d.relevantContentAxis = root.flickable.contentY

        d.relevantMouseAxis  = (root.horizontal ? mouse.x : mouse.y)
        if (d.relevantMouseAxis < d.lowerLimit && !d.atRelevantContentAxisBeginning) {
            startScrolling(false);
            mouse.accepted = true;
        } else if (d.relevantMouseAxis >= d.upperLimit && !d.atRelevantContentAxisEnd) {
            startScrolling(true);
            mouse.accepted = true;
        } else {
            stopScrolling();
        }

        //mouse.accepted = root.enabled
    }

    Mouse.onReleased: {
        stopScrolling();
        mouse.accepted = root.enabled
    }
}
