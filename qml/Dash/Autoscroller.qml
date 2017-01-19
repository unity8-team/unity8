/*
 * Copyright (C) 2017 Canonical, Ltd.
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

Item {
    id: autoscroller

    property bool dragging: false
    property var dragItem: new Object();
    property var flickable

    function autoscroll(dragging, dragItem) {
        if (dragging) {
            autoscroller.dragItem = dragItem;
            autoscroller.dragging = true;
        } else {
            autoscroller.dragItem = null;
            autoscroller.dragging = false;
        }
    }

    readonly property real bottomBoundary: {
        var contentHeight = flickable.contentHeight
        var contentY = flickable.contentY
        var dragItemHeight = dragItem ? autoscroller.dragItem.height : 0
        var heightRatio = flickable.visibleArea.heightRatio

        if (!dragItem) {
            return true;
        } else {
            return (heightRatio * contentHeight) -
                   (1.5 * dragItemHeight) + contentY
        }
    }

    readonly property int delayMs: 32
    readonly property real topBoundary: dragItem ? flickable.contentY + (.5 * dragItem.height) : 0

    visible: false
    readonly property real maxStep: units.dp(10)
    function stepSize(scrollingUp) {
        var delta, step;
        if (scrollingUp) {
            delta = dragItem.y - topBoundary;
            delta /= (1.5 * dragItem.height);
        } else {
            delta = dragItem.y - bottomBoundary;
            delta /= (1.5 * dragItem.height);
        }

        step = Math.abs(delta) * autoscroller.maxStep
        return Math.ceil(step);
    }

    Timer {
        interval: autoscroller.delayMs
        running: autoscroller.dragItem ? (autoscroller.dragging &&
            autoscroller.dragItem.y < autoscroller.topBoundary &&
            !flickable.atYBeginning) : false
        repeat: true
        onTriggered: {
            flickable.contentY -= autoscroller.stepSize(true);
            autoscroller.dragItem.y -= autoscroller.stepSize(true);
        }
    }

    Timer {
        interval: autoscroller.delayMs
        running: autoscroller.dragItem ? (autoscroller.dragging &&
            autoscroller.dragItem.y >= autoscroller.bottomBoundary &&
            !autoscroller.flickable.atYEnd) : false
        repeat: true
        onTriggered: {
            flickable.contentY += autoscroller.stepSize(false);
            autoscroller.dragItem.y += autoscroller.stepSize(false);
        }
    }
}
