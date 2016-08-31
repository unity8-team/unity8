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

    // Uses an animation to smooth scrolling.
    // This is useful for a large delay/step, but with smaller
    // values it creates too much lag and should be disabled.
    // The default value of 2dp/2ms ensures an update for every event loop
    // and an animation can't smooth that anyway.
    property bool smoothScrolling: false
    property bool variableVelocity: true
    property int delay: 2 // ms delay between scrolls
    property real areaLength: units.gu(5)
    property real maximumStep: units.dp(2)
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
        if (!root.variableVelocity) return root.maximumStep;
        var step;
        if (!progressiveScrollingTimer.scrollPositiveDirection) {
            var delta;
            delta = d.relevantMouseAxis - d.lowerLimit;
            delta = delta / root.areaLength;
            step = Math.abs(delta) * root.maximumStep;
        } else {
            delta = d.relevantMouseAxis - d.upperLimit;
            delta = delta / root.areaLength;
            step = Math.abs(delta) * root.maximumStep;
        }

        return Math.ceil(step);
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

        Behavior on relevantContentAxis {
            animation: UbuntuNumberAnimation{}
            enabled: root.smoothScrolling
        }
    }

    Timer {
        id: progressiveScrollingTimer

        property bool scrollPositiveDirection: true
        readonly property real listEnd: {
            if (root.horizontal) {
                return Math.floor((1 - root.flickable.visibleArea.widthRatio) *
                        root.flickable.contentWidth);
            } else {
                return Math.floor((1 - root.flickable.visibleArea.heightRatio) *
                        root.flickable.contentHeight);
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
                    stopScrolling();
                }
            } else if (scrollPositiveDirection && !d.atRelevantContentAxisEnd) {
                if (listEnd - d.relevantContentAxis > root.stepSize()) {
                    d.relevantContentAxis += root.stepSize();
                } else {
                    d.relevantContentAxis = listEnd;
                    stopScrolling();
                }
            }
        }
    }

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
    }

    Mouse.onReleased: {
        stopScrolling();
        mouse.accepted = root.enabled
    }
}
