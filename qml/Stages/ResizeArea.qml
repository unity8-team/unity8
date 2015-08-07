/*
 * Copyright (C) 2015 Canonical, Ltd.
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
import Unity.Application 0.1

MouseArea {
    id: root

    // to be set from outside
    property Item target
    property bool leftBorder: false
    property bool rightBorder: false
    property bool topBorder: false
    property bool bottomBorder: false

    property bool dragging: false
    property real startX
    property real startY
    property real startWidth
    property real startHeight

    hoverEnabled: true

    property string cursorName: {
        if (leftBorder && !topBorder && !bottomBorder) {
            return "left_side";
        } else if (rightBorder && !topBorder && !bottomBorder) {
            return "right_side";
        } else if (topBorder && !leftBorder && !rightBorder) {
            return "top_side";
        } else if (bottomBorder && !leftBorder && !rightBorder) {
            return "bottom_side";
        } else if (leftBorder && topBorder) {
            return "top_left_corner";
        } else if (leftBorder && bottomBorder) {
            return "bottom_left_corner";
        } else if (rightBorder && topBorder) {
            return "top_right_corner";
        } else if (rightBorder && bottomBorder) {
            return "bottom_right_corner";
        }
    }

    function updateCursorName() {
        if (containsMouse || pressed) {
            Mir.cursorName = root.cursorName;
        } else {
            Mir.cursorName = "";
        }
    }

    onContainsMouseChanged: {
        updateCursorName();
    }

    onPressedChanged: {
        updateCursorName();
        if (pressed) {
            var pos = mapToItem(target.parent, mouseX, mouseY);
            startX = pos.x;
            startY = pos.y;
            startWidth = target.width;
            startHeight = target.height;
            dragging = true;
        } else {
            dragging = false;
        }
    }

    onMouseXChanged: {
        if (!pressed || !dragging) {
            return;
        }

        var pos = mapToItem(target.parent, mouseX, mouseY);

        if (leftBorder) {
            if (startX + startWidth > pos.x + target.minWidth) {
                target.x = pos.x;
                target.width = startX + startWidth - target.x;
                startX = target.x;
                startWidth = target.width;
            } else if (startX + startWidth < pos.x + target.minWidth) {
                // don't let it get thinner than minWidth
                target.x = startX + startWidth - target.minWidth;
                target.width = target.minWidth;
            }

        } else if (rightBorder) {
            var deltaX = pos.x - startX;
            if (startWidth + deltaX >= target.minWidth) {
                target.width = startWidth + deltaX;
            } else {
                target.width = target.minWidth;
            }
        }
    }

    onMouseYChanged: {
        if (!pressed || !dragging) {
            return;
        }

        var pos = mapToItem(target.parent, mouseX, mouseY);

        if (topBorder) {

            if (startY + startHeight > pos.y + target.minHeight) {
                target.y = pos.y;
                target.height = startY + startHeight - target.y;
                startY = target.y;
                startHeight = target.height;
            } else if (startY + startHeight < pos.y + target.minHeight) {
                // don't let it get shorter than minHeight
                target.y = startY + startHeight - target.minHeight;
                target.height = target.minHeight;
            }

        } else if (bottomBorder) {
            var deltaY = pos.y - startY;
            if (startHeight + deltaY >= target.minHeight) {
                target.height = startHeight + deltaY;
            } else {
                target.height = target.minHeight;
            }
        }
    }
}
